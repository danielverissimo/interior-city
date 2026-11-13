#!/usr/bin/env python3
"""Restricted root receiver for the Interior City repository, installed by an admin.

The runner can request an exact master SHA, never supply a shell, archive or path.
Private configuration stays on Uriel; detailed installer output stays root-only.
"""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import traceback

sys.dont_write_bytecode = True
ROOT = Path('/opt/uriel/interior-city-tocado')
CONTROL = Path('/var/lib/interior-city-actions')
REMOTE = 'https://github.com/danielverissimo/interior-city.git'


class Refused(ValueError):
    pass


def parse_request(arguments):
    if arguments == ['status']:
        return 'status', None
    if (len(arguments) == 2 and arguments[0] in {'check', 'deploy'}
            and re.fullmatch('[0-9a-f]{40}', arguments[1])):
        return tuple(arguments)
    raise Refused('Use status, check SHA or deploy SHA.')


def run(arguments, log, **kwargs):
    result = subprocess.run(arguments, stdout=subprocess.PIPE, stderr=log, **kwargs)
    if result.returncode:
        raise Refused('Operational command failed; inspect the private server log.')
    return result.stdout


def current_release(root=ROOT):
    link = root / 'current'
    if not link.is_symlink():
        raise Refused('An existing managed release is required.')
    release = link.resolve(strict=True)
    if release.parent != root / 'releases' or not re.fullmatch('[0-9a-f]{40}', release.name):
        raise Refused('Unexpected current release.')
    return release


def master_archive(sha, target, log, control=CONTROL):
    repository = control / 'repository.git'
    if not repository.exists():
        run(['git', 'init', '--bare', str(repository)], log)
    git = ['git', '--git-dir=' + str(repository)]
    run(git + ['fetch', '--quiet', '--depth=1', REMOTE,
               '+refs/heads/master:refs/heads/master'], log, timeout=180)
    master = run(git + ['rev-parse', 'refs/heads/master'], log).decode().strip()
    if master != sha:
        raise Refused('Requested SHA is no longer the current master; deploy the latest run.')
    with target.open('xb') as archive:
        result = subprocess.run(git + ['archive', '--format=tar', sha], stdout=archive, stderr=log)
    if result.returncode:
        raise Refused('Could not prepare the exact master archive.')
    # No target-supplied archive is ever accepted over SSH.
    return git


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def preflight(candidate, previous, log, root=ROOT):
    selection = json.loads((root / 'state/ic-config/selection.json').read_text())
    if selection.get('phase') != 'active':
        raise Refused('Automatic deployment requires an already active IC Config installation.')
    cutover = load(candidate / 'scripts/ic-config-cutover.py', 'actions_cutover')
    cutover.configure_candidate(candidate)
    cutover.check_previous(root, previous, allow_admin=True)
    run(['python3', str(candidate / 'scripts/configure-secrets.py'),
         '--directory', str(root / 'secrets'), 'check'], log, timeout=60)
    assets = load(candidate / 'scripts/assets.py', 'actions_assets')
    lock = assets.validate_lock(json.loads((candidate / 'assets.lock.json').read_text()))
    # The selected full roster must have its immutable private objects on Uriel.
    store = Path('/srv/diskaux/interior-city-assets')
    for package in lock['packages']:
        if not (store / package['archive']['object']).is_file():
            raise Refused('A private asset object is missing; publish assets before the code deployment.')
    # Read actual running mount sources without changing or stopping writers.
    _, info = cutover.container_info()
    if not info['State'].get('Running') or info['State'].get('Health', {}).get('Status') != 'healthy':
        raise Refused('The current city must be healthy before automatic deployment.')
    states, _ = cutover.modules()
    for relative in states.FILES:
        source = cutover.source_file(root, previous, relative, info.get('Mounts', []))
        states.read_resource_json(source, relative)
    return {'stateFiles': len(states.FILES), 'privateAssetsAvailable': True}


def status(root=ROOT):
    release = current_release(root)
    return {'current': release.name,
            'configPhase': json.loads((root / 'state/ic-config/selection.json').read_text()).get('phase')}


def execute(mode, sha, log, root=ROOT, control=CONTROL):
    previous = current_release(root)
    with tempfile.TemporaryDirectory(prefix='candidate-', dir=control) as directory:
        stage = Path(directory)
        archive = stage / 'release.tar'
        git = master_archive(sha, archive, log, control)
        helper = stage / 'release.py'
        helper.write_bytes(run(git + ['show', sha + ':scripts/release.py'], log))
        load(helper, 'actions_extract').extract(archive, stage / 'inspection')
        candidate = stage / 'inspection'
        details = preflight(candidate, previous, log, root)
        if mode == 'check':
            return {'mode': mode, 'sha': sha, 'current': previous.name, **details}
        if previous.name == sha:
            return {'mode': mode, 'sha': sha, 'installed': True, 'alreadyCurrent': True}
        # Execute pristine installer/helpers from the same SHA. Rendering above is
        # an isolated preview; the immutable archive remains the Git commit bytes.
        for name in ['install-uriel-release.sh', 'ic-admin-cutover.py', 'ic-admin-migrate.py',
                     'ic-config-cutover.py', 'ic-config-state.py', 'ic-mansions-import.py']:
            (stage / name).write_bytes(run(git + ['show', sha + ':scripts/' + name], log))
        # stdout can include resource-specific values, so retain it privately.
        result = subprocess.run(['bash', str(stage / 'install-uriel-release.sh'), sha,
                                 str(archive), '--ic-admin-cutover', '--ic-config-cutover'],
                                stdout=log, stderr=log)
        if result.returncode:
            raise Refused('Installer failed; inspect private logs and retained state on Uriel.')
        if current_release(root).name != sha:
            raise Refused('Installer completed without selecting the requested release.')
        return {'mode': mode, 'sha': sha, 'previous': previous.name, 'installed': True}


def main(arguments):
    mode, sha = parse_request(arguments)
    if os.geteuid() != 0:
        raise Refused('This receiver must be invoked through its restricted sudo rule.')
    os.umask(0o077)
    if mode == 'status':
        print(json.dumps(status()))
        return
    CONTROL.mkdir(mode=0o700, exist_ok=True)
    with (CONTROL / 'actions.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise Refused('Another Actions request is running.') from None
        logs = CONTROL / 'logs'
        logs.mkdir(mode=0o700, exist_ok=True)
        path = logs / f'{int(time.time())}-{mode}-{sha}.log'
        with path.open('x') as log:
            try:
                result = execute(mode, sha, log)
            except Exception:
                traceback.print_exc(file=log)
                print('Request failed; private diagnostics: ' + str(path), file=sys.stderr)
                raise
        print(json.dumps(result))


if __name__ == '__main__':
    try:
        main(sys.argv[1:])
    except Exception:
        print('Request refused or failed before verification. Inspect the private Uriel log.', file=sys.stderr)
        sys.exit(1)
