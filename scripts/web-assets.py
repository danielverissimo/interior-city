#!/usr/bin/env python3
"""Import static XAMPP media and configure legacy URLs in an isolated release."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
from urllib.parse import urlsplit

MEDIA = {
    'images': {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.ico'},
    'vrp_images': {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.ico'},
    'loading': {'.mp3', '.mp4', '.ogg', '.wav', '.webm'},
}
LEGACY = re.compile(r'http://(?:127\.0\.0\.1|localhost)/(images|vrp_images|loading)/')
TEXT = {'.lua', '.js', '.json', '.html', '.css', '.ts', '.tsx'}


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def real_directory(path):
    path = Path(os.path.abspath(path))
    if any(p.is_symlink() for p in (path, *path.parents)):
        raise ValueError('Media directories must not use symlinks')
    return path


def inventory(root):
    root = real_directory(root)
    result = {}
    for path in sorted(root.rglob('*')):
        if path.is_symlink() or not (path.is_dir() or path.is_file()):
            raise ValueError('Links and special files are not allowed in static media')
        if path.is_dir():
            continue
        relative = path.relative_to(root)
        if (len(relative.parts) < 2 or relative.parts[0] not in MEDIA
                or path.suffix.lower() not in MEDIA[relative.parts[0]]
                or any(part.startswith('.') for part in relative.parts)):
            raise ValueError('Unexpected file in the public media directory')
        result[relative.as_posix()] = {'size': path.stat().st_size, 'sha256': digest(path)}
    return result


def import_media(source, destination):
    source, destination = real_directory(source), real_directory(destination)
    if (not source.is_dir() or source == destination or source in destination.parents
            or destination in source.parents):
        raise ValueError('Use a real source and a separate destination')
    planned, skipped = {}, 0
    for group, extensions in MEDIA.items():
        folder = source / group
        if not folder.is_dir() or folder.is_symlink():
            raise ValueError('Missing static media source directory')
        for path in sorted(folder.rglob('*')):
            if path.is_symlink() or not (path.is_dir() or path.is_file()):
                raise ValueError('Source media must not contain links or special files')
            if path.is_dir():
                continue
            relative = path.relative_to(source)
            if path.suffix.lower() not in extensions or any(p.startswith('.') for p in relative.parts):
                skipped += 1
                continue
            planned[relative.as_posix()] = path
    if not planned:
        raise ValueError('No static media to import')
    if len({p.casefold() for p in planned}) != len(planned):
        raise ValueError('Ambiguous file names on case-insensitive filesystems')
    manifest = destination.with_name(destination.name + '.manifest.json')
    if manifest.is_symlink():
        raise ValueError('Manifest must not be a symlink')
    destination.mkdir(parents=True, exist_ok=True)
    existing = inventory(destination)
    if set(existing) - set(planned):
        raise ValueError('Destination contains files outside this import')
    records = {}
    for relative, path in planned.items():
        record = {'size': path.stat().st_size, 'sha256': digest(path)}
        if relative in existing and existing[relative] != record:
            raise ValueError('Refusing to overwrite different existing media')
        records[relative] = record
    # Validate the whole plan before writing; never overwrite divergent media.
    for relative, path in planned.items():
        out = destination / relative
        out.parent.mkdir(parents=True, exist_ok=True)
        if relative not in existing:
            with path.open('rb') as src, out.open('xb') as dst:
                shutil.copyfileobj(src, dst, 1024 * 1024)
        out.chmod(0o644)
    for folder in [destination, *(p for p in destination.rglob('*') if p.is_dir())]:
        folder.chmod(0o755)
    if inventory(destination) != records:
        raise ValueError('Media verification failed after import')
    manifest.write_text(json.dumps({'format': 1, 'files': records}, indent=2, sort_keys=True) + '\n')
    manifest.chmod(0o600)
    return {'files': len(records), 'bytes': sum(r['size'] for r in records.values()), 'excluded': skipped}


def verify_media(destination):
    destination = real_directory(destination)
    manifest = destination.with_name(destination.name + '.manifest.json')
    if manifest.is_symlink():
        raise ValueError('Manifest must not be a symlink')
    expected = json.loads(manifest.read_text())
    if expected.get('format') != 1 or not expected.get('files') or inventory(destination) != expected['files']:
        raise ValueError('Static media do not match their manifest')
    return {'verified': len(expected['files'])}


def base_url(value):
    url = urlsplit(value)
    # Public origin only: credentials, paths, queries and fragments do not belong here.
    if (url.scheme != 'https' or not url.hostname or url.username or url.password
            or url.path not in ('', '/') or url.query or url.fragment
            or not re.fullmatch(r'[A-Za-z0-9.-]+(?::[0-9]{1,5})?', url.netloc)
            or any(ord(c) < 33 for c in value) or (url.port is not None and not 0 < url.port < 65536)):
        raise ValueError('Configure a public HTTPS origin for static media')
    if url.hostname in ('localhost', '127.0.0.1', '0.0.0.0'):
        raise ValueError('The production media origin must be reachable by players')
    return value.rstrip('/')


def configure_release(release, origin, media=None):
    release = Path(release)
    if (release / '.git').exists():
        raise ValueError('Render an isolated release; never rewrite the Git checkout')
    marker = release / 'config/web-assets.runtime.json'
    if marker.exists():
        recorded = json.loads(marker.read_text())
        if recorded['origin'] != base_url(origin):
            raise ValueError('An existing release cannot change its sealed media origin')
        if media is not None:
            verify_media(media)
        for relative, expected in recorded['files'].items():
            if digest(release / relative) != expected:
                raise ValueError('Configured resource changed after rendering')
        return {'configured': len(recorded['files'])}
    replacements = []
    for path in sorted((release / 'resources').rglob('*')):
        if path.is_symlink():
            raise ValueError('Release resources must not contain symlinks')
        if path.is_file() and path.suffix in TEXT:
            content = path.read_bytes().decode('utf-8', errors='surrogateescape')
            if LEGACY.search(content):
                replacements.append((path, content))
    if not replacements:
        return {'configured': 0}
    origin = base_url(origin)
    if media is not None:
        verify_media(media)
    for path, content in replacements:
        content = LEGACY.sub(lambda match: origin + '/' + match[1] + '/', content)
        # The original Windows craft UI asks for .PNG; imported files use .png.
        content = re.sub(r'(' + re.escape(origin) + r'/images/[^\s\x22\x27`<>]*)\.PNG', r'\1.png', content)
        path.write_bytes(content.encode('utf-8', errors='surrogateescape'))
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text(json.dumps({'origin': origin, 'files': {
        path.relative_to(release).as_posix(): digest(path) for path, _ in replacements
    }}, indent=2, sort_keys=True) + '\n')
    return {'configured': len(replacements)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('import'); p.add_argument('--source', required=True); p.add_argument('--destination', required=True)
    p = sub.add_parser('verify'); p.add_argument('--destination', required=True)
    p = sub.add_parser('configure'); p.add_argument('--release', required=True)
    p.add_argument('--base-url', default=''); p.add_argument('--media')
    args = parser.parse_args()
    if args.command == 'import':
        result = import_media(args.source, args.destination)
    elif args.command == 'verify':
        result = verify_media(args.destination)
    else:
        result = configure_release(args.release, args.base_url, args.media)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, UnicodeError):
        print('Static media operation failed: check origin, source, file integrity and permissions.', file=sys.stderr)
        sys.exit(1)
