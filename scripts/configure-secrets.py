#!/usr/bin/env python3
"""Manage ignored Docker secrets without logging their values (Python stdlib)."""
import argparse
import getpass
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASE_NAMES = {'cfx_license', 'steam_web_api', 'playit_agent_key', 'webhook_logs', 'webhook_bugs'}
DB_NAMES = {'db_root_password', 'db_app_password'}


def write_private(path, value):
    path = Path(path)
    if path.is_symlink():
        raise ValueError('Refusing a secret symlink')
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as output:
        temporary = Path(output.name)
        try:
            output.write(value.encode()); output.flush()
            os.fchmod(output.fileno(), 0o600 if path.name == 'resource_secrets.json' else 0o444)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def valid_value(value):
    return (isinstance(value, str) and len(value) <= 8192
            and not any(ord(c) < 32 or ord(c) == 127 or c in '\\"' for c in value))


def validate(name, value):
    if not valid_value(value): raise ValueError('Invalid secret characters; value omitted')
    if name == 'cfx_license' and value and not re.fullmatch(r'cfxk_[A-Za-z0-9_-]+', value):
        raise ValueError('Invalid Cfx license format')
    if name in DB_NAMES and not re.fullmatch(r'[a-fA-F0-9]{48}', value):
        raise ValueError('Invalid database password format')
    if name == 'steam_web_api' and value and not re.fullmatch(r'[a-fA-F0-9]{32}', value):
        raise ValueError('Invalid Steam key format')


def initialize(directory):
    directory = Path(directory)
    if directory.is_symlink(): raise ValueError('Refusing a secret directory symlink')
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    directory.chmod(0o700)
    for name in sorted(BASE_NAMES | DB_NAMES):
        if not (directory/name).exists():
            write_private(directory/name, secrets.token_hex(24) if name in DB_NAMES else '')
    if not (directory/'resource_secrets.json').exists():
        write_private(directory/'resource_secrets.json', '{}\n')
    if (directory/'resource_secrets.json').is_symlink(): raise ValueError('Refusing a secret symlink')
    (directory/'resource_secrets.json').chmod(0o600)


def render(directory, schema):
    directory = Path(directory)
    if directory.is_symlink() or any((directory/name).is_symlink() for name in BASE_NAMES | DB_NAMES | {'resource_secrets.json'}):
        raise ValueError('Refusing a secret symlink')
    allowed = json.loads(Path(schema).read_text())
    values = json.loads((directory/'resource_secrets.json').read_text())
    if not isinstance(values, dict) or set(values)-set(allowed):
        raise ValueError('Unknown resource secret names (values omitted)')
    for name in BASE_NAMES | DB_NAMES:
        validate(name, (directory/name).read_text().rstrip('\n'))
    lines = []
    for name, value in sorted(values.items()):
        if not re.fullmatch(r'ic_secret_[a-z0-9_]+', name) or not valid_value(value):
            raise ValueError('Invalid resource secret; value omitted')
        if value and allowed[name]['type'] == 'webhook' and not re.fullmatch(
                r'https://(?:(?:canary|ptb)\.)?discord(?:app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9_.-]+', value):
            raise ValueError('Invalid Discord webhook format; value omitted')
        if value: lines.append(name+'='+value+'\n')
    write_private(directory/'resource_convars', ''.join(lines))


def import_package(directory, source, include_resources=False):
    """Explicit opt-in: import licenses only, never supplier webhooks or DB users."""
    source, directory = Path(source), Path(directory)
    candidates = [source/'config/keys.cfg', source/'config/config.cfg']
    names = {'sv_licensekey':'cfx_license', 'steam_webapikey':'steam_web_api'}
    found = {}
    for path in candidates:
        if not path.is_file(): continue
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            if line.lstrip().startswith(('#', '//')): continue
            parts = shlex.split(line, comments=True)
            if parts and parts[0].lower() in {'set', 'sets', 'setr'}: parts = parts[1:]
            if len(parts) >= 2 and parts[0].lower() in names:
                name, value = names[parts[0].lower()], parts[1]
                validate(name, value); found[name] = value
    if 'cfx_license' not in found: raise ValueError('No supported Cfx license found in package CFG')
    resource_values = json.loads((directory/'resource_secrets.json').read_text())
    if include_resources:
        phone = source/'resources/[smartphone]/smartphone/config.json'
        if phone.is_file():
            value = json.loads(phone.read_text(encoding='utf-8-sig')).get('token', '')
            if value and not re.search(r'(?i)defina|your.?token|seu.?token|example', value):
                if not valid_value(value): raise ValueError('Invalid resource license format')
                if resource_values.get('ic_secret_smartphone_token') not in (None, '', value):
                    raise ValueError('Resource license already configured')
                resource_values['ic_secret_smartphone_token'] = value
        for path, variable, key in [
            ('resources/[scriptcore]/m_survival/config/config_server.lua', r'config\.token', 'ic_secret_survival_token'),
            ('resources/[vrp]/vrp_admin/logs.lua', r'local\s+API_KEY', 'ic_secret_logs_api_key'),
        ]:
            text = (source/path).read_text(encoding='utf-8-sig')
            match = re.search(variable+r'''\s*=\s*(["'])([^"'\r\n]+)\1''', text)
            if match and not re.search(r'(?i)defina|your.?token|seu.?token|example|^api_key$', match[2]):
                if not valid_value(match[2]): raise ValueError('Invalid resource license format')
                if resource_values.get(key) and resource_values[key] != match[2]:
                    raise ValueError('Resource license already configured')
                resource_values[key] = match[2]
    for name, value in found.items():
        if (directory/name).read_text().strip() not in ('', value):
            raise ValueError('Destination license already configured; use set to rotate explicitly')
    for name, value in found.items(): write_private(directory/name, value)
    if include_resources:
        write_private(directory/'resource_secrets.json', json.dumps(resource_values, indent=2)+'\n')
    print('Package license files imported privately; no values displayed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', default=str(ROOT/'secrets'))
    parser.add_argument('--schema', default=str(ROOT/'config/resource-secrets.schema.json'))
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('init'); sub.add_parser('render'); sub.add_parser('check')
    p = sub.add_parser('set'); p.add_argument('name', choices=sorted(BASE_NAMES))
    p = sub.add_parser('import-package'); p.add_argument('source'); p.add_argument('--include-resource-licenses', action='store_true')
    args = parser.parse_args(); directory = Path(args.directory)
    if args.command == 'init': initialize(directory)
    elif args.command == 'set':
        if not sys.stdin.isatty(): raise ValueError('An interactive terminal is required')
        value = getpass.getpass(args.name+' (input hidden): ')
        validate(args.name, value); write_private(directory/args.name, value)
    elif args.command == 'import-package': import_package(directory, args.source, args.include_resource_licenses)
    if args.command == 'check':
        for name in BASE_NAMES | DB_NAMES:
            validate(name, (directory/name).read_text().rstrip('\n'))
        if not (directory/'cfx_license').read_text().strip(): raise ValueError('Cfx license is empty')
    render(directory, args.schema)
    print('Private secret configuration validated; values omitted.')


if __name__ == '__main__':
    try: main()
    except (ValueError, OSError) as error:
        # JSON errors can include input: never print exception messages from parsers.
        print('Secret configuration failed; check paths, field names and formats. No values logged.', file=sys.stderr)
        sys.exit(1)
