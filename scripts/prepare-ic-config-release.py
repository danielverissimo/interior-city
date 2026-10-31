#!/usr/bin/env python3
"""Build a private reviewable candidate using an isolated Git index.

No checkout, current branch/index mutation, push, SSH, upload or deployment.
Only the explicitly owned paths below are admitted from the working tree.
"""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import types

ROOT=Path(__file__).resolve().parents[1]
OWNED=[
    'README.md','docs/IC_CONFIG.md','docs/IC_CONFIG_FORMS.md','docs/IC_MANSIONS.md','docs/IC_CONFIG_INSTALL.md','docs/evidence',
    'config/ic_config.example.cfg','config/ic_mansions.example.cfg','config/ic_config_release.json','database/ic_config',
    'resources/[scriptcore]/ic_config','resources/[scriptcore]/ic_mansions',
    'resources/[scriptcore]/dm_spawn/server/server.lua',
    'resources/[scriptcore]/inventory/server/modules/chest.lua',
    'resources/[scriptcore]/m_garage/server-side/functions.lua',
    'resources/[scriptcore]/m_garage/server-side/configManager.lua',
    'resources/[scripts]/doorsv2/doors_client.lua','resources/[scripts]/doorsv2/doors_server.lua',
    'resources/[scripts]/m_orgs_v2/server/00_dynamic_orgs.lua',
    'resources/[vrp]/vrp/base.lua','resources/[vrp]/vrp/server-side/group.lua',
    'scripts/ic-config-cutover.py','scripts/ic-config-state.py','scripts/ic-config-migrate.py',
    'scripts/ic-mansions-import.py','scripts/analysis/inspect-mansion-contract.py',
    'scripts/prepare-ic-config-release.py','scripts/install-uriel-release.sh',
    'scripts/deploy-uriel.sh','scripts/ic-admin-cutover.py','docker/backup/backup.sh',
    'tests/test_docker_release.py'
]

def git(args,env=None,input=None):
    result=subprocess.run(['git',*args],cwd=ROOT,env=env,input=input,capture_output=True,text=True)
    if result.returncode:raise ValueError('Git candidate operation failed; no branch/index was changed')
    return result.stdout.strip()

def load(path,name):
    value=types.ModuleType(name);value.__file__=str(path)
    exec(compile(path.read_text(),str(path),'exec'),value.__dict__);return value

def prepare(output,validation_report=None,base_commit=None):
    if not output.is_absolute()or '..'in output.parts or any(p.is_symlink()for p in(output,*output.parents)):
        raise ValueError('Use an absolute new output directory without symlinks')
    if output.exists():raise ValueError('Output already exists')
    owned=[path for path in OWNED if(ROOT/path).exists()]
    owned+=sorted(str(path.relative_to(ROOT))for path in(ROOT/'tests').glob('*ic_config*')if path.is_file())
    owned+=sorted(str(path.relative_to(ROOT))for path in(ROOT/'tests').glob('*ic_mansions*')if path.is_file())
    for name in('state-a.json','state-b.json'):
        state=json.loads((ROOT/'resources/[scriptcore]/ic_mansions'/name).read_text())
        if state.get('generation')!=0 or state.get('state',{}).get('mansions'):
            raise ValueError('Operational mansion state cannot be admitted to source release')
    output.mkdir(parents=True,mode=0o700)
    output.chmod(0o700)
    source_head=git(['rev-parse','HEAD'])
    if base_commit is not None and not re.fullmatch('[0-9a-f]{40}',base_commit):
        raise ValueError('The deployed baseline must be a full commit SHA')
    base=git(['rev-parse','--verify',(base_commit or source_head)+'^{commit}'])
    with tempfile.TemporaryDirectory(prefix='ic-config-index-')as tmp:
        env=dict(os.environ,GIT_INDEX_FILE=str(Path(tmp)/'index'))
        git(['read-tree',base],env)
        git(['add','--',*owned],env)
        included=git(['diff','--cached','--name-only',base],env).splitlines()
        tree=git(['write-tree'],env)
        message=('Complete independent IC Config and mansion system; explicit tested Uriel cutover.\n\n'
                 'Local review candidate. No publication or deployment performed.\n')
        commit=git(['-c','commit.gpgsign=false','commit-tree',tree,'-p',base],env,message)
        # Include newly added files in the final whitespace gate too.
        git(['diff','--check',base,commit],env)
    # A separate local ref keeps the candidate available without changing HEAD.
    ref='refs/heads/codex/ic-config-candidate-'+commit[:12]
    git(['update-ref',ref,commit,''])
    archive=output/'release.tar.gz'
    git(['archive','--format=tar.gz','--output='+str(archive),commit])
    helper=load(ROOT/'scripts/release.py','candidate_release')
    configure=load(ROOT/'scripts/ic-config-cutover.py','candidate_configure')
    with tempfile.TemporaryDirectory(prefix='ic-config-inspection-')as tmp:
        inspection=Path(tmp)/'release'
        helper.extract(archive,inspection)
        helper.manifest(inspection,output/'source-manifest.json')
        configure.configure_candidate(inspection)
        helper.manifest(inspection,output/'provider-preview-manifest.json')
        configure.validate_candidate(inspection)
    changes=git(['diff','--name-only',base]).splitlines()
    excluded=sorted(set(changes)-set(included))
    report={'version':1,'baseCommit':base,'sourceHead':source_head,'candidateCommit':commit,'localRef':ref,
        'archive':archive.name,'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
        'includedWorkingPaths':included,'excludedTrackedChanges':excluded,
        'defaultIndexAndBranchUnchanged':True,'hostContacted':False,'deployed':False,
        'providerSelectionRenderedOnlyInPreview':True,'assetsDistributedSeparately':True,
        'nativeGameClientsValidated':False}
    if validation_report:
        data=json.loads(validation_report.read_text())
        (output/'validation.json').write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
        report['validationSha256']=hashlib.sha256((output/'validation.json').read_bytes()).hexdigest()
    (output/'candidate.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    for path in output.iterdir():path.chmod(0o600)
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--validation-report',type=Path)
    parser.add_argument('--base-commit',help='Full deployed SHA; preserve unrelated files from that release')
    args=parser.parse_args()
    try:print(json.dumps(prepare(args.output,args.validation_report,args.base_commit),indent=2,sort_keys=True))
    except (ValueError,OSError,subprocess.SubprocessError):
        print('Candidate preparation failed; inspect the private output directory. No upload or deployment was attempted.',file=sys.stderr)
        raise SystemExit(1)
