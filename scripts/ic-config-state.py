#!/usr/bin/env python3
"""Prepare a private, explicit configuration snapshot and optional Compose overlay.

Never selects a server, stops writers, starts Compose or modifies a release.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


FILES = {
    'resources/[scriptcore]/inventory/config/shared.chests.json': dict,
    'resources/[scriptcore]/inventory/config/shared.shops.json': dict,
    'resources/[scriptcore]/m_garage/shared-side/garages.json': list,
    'resources/[scriptcore]/m_garage/shared-side/typeGarages.json': dict,
    'resources/[scriptcore]/m_garage/shared-side/listcars.json': dict,
    'resources/[scripts]/m_craft/shared/config.json': dict,
    'resources/[scripts]/m_farm/shared/config.json': dict,
    'resources/[scriptcore]/m_skinshop/shareds-side/localesSkinshop.json': dict,
    'resources/[scriptcore]/m_barbershop/shared-side/shared.locations.json': dict,
    'resources/[scriptcore]/m_tattoos/shared/locations.json': dict,
    'resources/[roupas]/m_cloakroom/config.json': dict,
    'resources/[scriptcore]/m_snippets/config/blips.json': dict,
    'resources/[vrp]/vrp/cfg/groups.json': dict,
    'resources/[scripts]/m_orgs_v2/dynamic_orgs.json': dict,
    'resources/[scripts]/m_desmanche/config.json': dict,
    'resources/[scriptcore]/PolySafeZone/safezones.json': dict,
    'resources/[scriptcore]/m_empregos/jobs.json': dict,
    'resources/[roubos]/m_roubos/roubos.json': dict,
    'resources/[roubos]/m_banco_central/banco_central.json': dict,
    'resources/[roubos]/m_joalheria/joalheria.json': dict,
    'resources/[roubos]/m_roubocofre/roubocofre.json': dict,
    'resources/[scripts]/residences/residences.json': dict,
    'resources/[scripts]/m_dealership/dealership.json': dict,
    'resources/[scriptcore]/m_mansions/mansions.json': dict,
    'resources/[scriptcore]/ic_mansions/state-a.json': dict,
    'resources/[scriptcore]/ic_mansions/state-b.json': dict,
    'resources/[scriptcore]/ic_mansions/catalog.json': dict,
    'resources/[scripts]/doorsv2/doors.json': list,
}


class StateError(Exception):
    pass


def safe_path(path):
    if not path.is_absolute() or '..' in path.parts:
        raise StateError('Use caminhos absolutos sem ..')
    if any(p.is_symlink() for p in (path, *path.parents)):
        raise StateError('Links simbólicos não são aceitos.')
    return path


def read_json(path, expected=None):
    safe_path(path)
    if not path.is_file() or path.stat().st_size > 16 * 1024 * 1024:
        raise StateError('Arquivo ausente, inválido ou acima de 16 MiB.')
    raw = path.read_bytes()
    try:
        value = json.loads(raw, parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
    except (ValueError, UnicodeError):
        raise StateError('JSON inválido; conteúdo omitido.') from None
    if expected and not isinstance(value, expected):
        raise StateError('Formato JSON incompatível; conteúdo omitido.')
    return raw, value


def acquire(source_root, source_map=None):
    safe_path(source_root)
    overrides = {}
    if source_map:
        _, overrides = read_json(source_map, dict)
        if set(overrides) - set(FILES) or any(not isinstance(v, str) for v in overrides.values()):
            raise StateError('Mapa de fontes contém caminhos não reconhecidos.')
    payloads = {}
    for relative, expected in FILES.items():
        selected = Path(overrides[relative]) if relative in overrides else source_root / relative
        try:
            raw, _ = read_json(selected, expected)
        except (OSError, StateError):
            raise StateError(f'Fonte recusada: {relative}. Verifique o caminho efetivo e o JSON.') from None
        payloads[relative] = raw
    return payloads


def prepare(source_root, output, source_map=None, *, apply=False, writers_stopped=False):
    safe_path(output)
    if output.exists():
        raise StateError('O destino deve ser um diretório novo; nada foi sobrescrito.')
    payloads = acquire(source_root, source_map)
    hashes = {p: hashlib.sha256(raw).hexdigest() for p, raw in payloads.items()}
    manifest = {'version': 1, 'files': hashes,
                'scope': 'configuration-files-only; database and KVP require separate backup'}
    report = {'files': len(hashes), 'bytes': sum(map(len, payloads.values())), 'applied': False}
    if not apply:
        return report
    if not writers_stopped:
        raise StateError('--apply exige --writers-stopped; pare todos os escritores antes.')
    if not output.parent.is_dir():
        raise StateError('O diretório pai do destino deve existir.')
    staging = Path(tempfile.mkdtemp(prefix='.ic-config-', dir=output.parent))
    try:
        for relative, raw in payloads.items():
            target = staging / relative
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            with target.open('xb') as stream:
                os.chmod(target, 0o600)
                stream.write(raw)
        (staging / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        os.chmod(staging / 'manifest.json', 0o600)
        # Long mount syntax refuses missing files instead of creating directories.
        lines = ['# Optional validation overlay; the release installer does not load this file.',
                 'services:', '  fxserver:', '    volumes:']
        for relative in FILES:
            lines += ['      - type: bind',
                      '        source: ' + json.dumps(str(output / relative), ensure_ascii=False),
                      '        target: ' + json.dumps('/server-data/' + relative),
                      '        read_only: false',
                      '        bind:', '          create_host_path: false']
        (staging / 'compose.ic-config.yaml').write_text('\n'.join(lines) + '\n')
        os.chmod(staging / 'compose.ic-config.yaml', 0o600)
        # Reserve the destination exclusively. A concurrent creator must win or
        # lose at mkdir, never have its directory replaced by rename.
        output.mkdir(mode=0o700)
        try:
            for relative in (*FILES, 'compose.ic-config.yaml', 'manifest.json'):
                target = output / relative
                target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                with target.open('xb') as stream:
                    os.chmod(target, 0o600)
                    stream.write((staging / relative).read_bytes())
        except BaseException:
            shutil.rmtree(output)
            raise
        report['applied'] = True
        return report
    finally:
        if staging.exists():
            shutil.rmtree(staging)


def verify(output):
    safe_path(output)
    _, manifest = read_json(output / 'manifest.json', dict)
    hashes = manifest.get('files')
    if manifest.get('version') != 1 or not isinstance(hashes, dict) or set(hashes) != set(FILES):
        raise StateError('Manifesto incompatível.')
    for relative, expected in FILES.items():
        raw, _ = read_json(output / relative, expected)
        if hashlib.sha256(raw).hexdigest() != hashes[relative]:
            raise StateError(f'Snapshot alterado: {relative}. Não restaure sobre estado operacional.')
    return {'files': len(FILES), 'verified': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('prepare', 'verify'))
    parser.add_argument('--source-root', type=Path)
    parser.add_argument('--source-map', type=Path,
                        help='JSON privado: caminho relativo conhecido -> arquivo efetivo absoluto')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--writers-stopped', action='store_true')
    args = parser.parse_args()
    try:
        if args.command == 'verify':
            result = verify(args.output)
        else:
            if not args.source_root:
                parser.error('prepare exige --source-root')
            result = prepare(args.source_root, args.output, args.source_map,
                             apply=args.apply, writers_stopped=args.writers_stopped)
        print(json.dumps(result))
    except (StateError, OSError):
        # Never print OSError text or JSON values: source paths can be private.
        print('Preparação/verificação recusada. Confira fontes, JSON, permissões, destino novo e parada dos escritores.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
