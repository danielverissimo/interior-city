#!/usr/bin/env python3
"""Safe release extraction and manifests; never executes supplied game resources."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import sys
import tarfile
import unicodedata

IGNORED = {'cache', 'runtime', '.assets-cache', '.assets-state.json'}
PRIVATE = {'secrets', '.env', '.env.dev', '.assets-store.json', 'state', 'txData', 'backups', '.git'}


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024**2), b''): h.update(block)
    return h.hexdigest()


def safe_name(name):
    name = unicodedata.normalize('NFC', name)
    path = PurePosixPath(name.rstrip('/'))
    if (not path.parts or path.is_absolute() or str(path) != name.rstrip('/')
            or any(p in {'.', '..'} for p in path.parts) or '\\' in name
            or any(ord(c) < 32 for c in name)):
        raise ValueError('Unsafe archive path')
    if path.parts[0] in PRIVATE or (path.parts[0].startswith('.env') and name != '.env.example'):
        raise ValueError('Private state in release archive')
    if path.parts[0] in IGNORED or path.as_posix() == 'config/keys.cfg':
        raise ValueError('Runtime state in release archive')
    return path


def extract(archive, destination):
    destination = Path(destination)
    if destination.is_symlink() or (destination.exists() and any(destination.iterdir())):
        raise ValueError('Release extraction requires an empty real directory')
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive, 'r:*') as tar:
        members, seen = [], set()
        for member in tar:
            path = safe_name(member.name)
            if str(path) in seen or not (member.isfile() or member.isdir()):
                raise ValueError('Duplicate, link or special archive member')
            seen.add(str(path)); members.append((member, path))
        for member, path in members:
            out = destination.joinpath(*path.parts)
            out.parent.mkdir(parents=True, exist_ok=True)
            if member.isdir(): out.mkdir(exist_ok=True); continue
            with tar.extractfile(member) as source, out.open('xb') as target:
                shutil.copyfileobj(source, target, 1024**2)
            out.chmod(0o755 if member.mode & 0o111 else 0o644)


def inventory(root):
    root = Path(root)
    result = {}
    for parent, directories, files in os.walk(root, followlinks=False):
        relative = Path(parent).relative_to(root)
        if relative == Path('.'):
            directories[:] = [d for d in directories if d not in IGNORED]
        for name in directories + files:
            if (Path(parent)/name).is_symlink(): raise ValueError('Unexpected release symlink')
        for name in files:
            path = Path(parent)/name; rel = path.relative_to(root).as_posix()
            if relative == Path('.') and name in IGNORED: continue
            safe_name(rel)
            result[rel] = sha(path)
    return result


def manifest(root, path, check=False):
    actual = inventory(root)
    path = Path(path)
    if check:
        if actual != json.loads(path.read_text()):
            raise ValueError('Release changed: review txAdmin/resource edits before continuing')
    else:
        if path.exists(): raise ValueError('Refusing to replace an existing pristine manifest')
        with path.open('x') as output: json.dump(actual, output, sort_keys=True)
        path.chmod(0o600)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest='command', required=True)
    p = subs.add_parser('extract'); p.add_argument('archive'); p.add_argument('destination')
    p = subs.add_parser('manifest'); p.add_argument('root'); p.add_argument('path'); p.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.command == 'extract': extract(args.archive, args.destination)
    else: manifest(args.root, args.path, args.check)


if __name__ == '__main__':
    try: main()
    except (ValueError, OSError, tarfile.TarError):
        print('Release validation failed: unsafe archive, unexpected file or modified manifest.', file=sys.stderr)
        sys.exit(1)
