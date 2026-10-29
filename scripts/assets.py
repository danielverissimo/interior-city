#!/usr/bin/env python3
"""Separate a supplied FiveM base and verify private, immutable asset packages.

Standard library only. Never executes supplied resources or expands nested archives.
"""
import argparse
import collections
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import unicodedata

PROJECT = 'tocado-mago'
CHUNK = 512 * 1024**2
HEAVY = {'[veiculos]', '[roupas]', '[mapas]'}
SKIP_DIRS = {'.git', 'node_modules', '__pycache__', 'cache', 'crashes', 'logs'}
ASSET_EXT = set('yft ytd ydr ydd ybn ymap ytyp ynv ycd awc rpf ypt ymt yld rel dat ymf ynd gfx fxap '
                'png jpg jpeg gif webp dds bmp ico ogg mp3 mp4 wav webm ttf otf woff woff2 eot '
                'zip rar 7z psd blend fbx mesh wasm dll exe pdb'.split())
CFX = re.compile(r'cfxk_[A-Za-z0-9_-]+')
WEBHOOK = re.compile(r'https?://(?:(?:canary|ptb)\.)?discord(?:app)?\.com/api/webhooks/[^\s"\'<>`]+', re.I)
MYSQL = re.compile(r'mysql://[^\s"\'<>`]+', re.I)
SENSITIVE = re.compile(r'''(?i)((?:(?<![\w"'`])\b(?:password|passwd|api[_-]?key|secret[_-]?key|access[_-]?token|client[_-]?secret|auth[_-]?token|license[_-]?key|steam[_-]?key|bot[_-]?token|token)\b|["'](?:password|passwd|api_key|secret_key|access_token|client_secret|auth_token|license_key|steam_key|bot_token|token)["'])\s*[:=]\s*)(["'])([^"'\r\n]{6,})\2''')


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()


def digest(value):
    return hashlib.sha256(value).hexdigest()


def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as stream:
        for block in iter(lambda: stream.read(1024**2), b''):
            h.update(block)
    return h.hexdigest()


def save_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile('w', dir=path.parent, delete=False, encoding='utf-8') as out:
        json.dump(value, out, indent=2, ensure_ascii=False)
        out.write('\n')
        temporary = Path(out.name)
    os.chmod(temporary, 0o644)
    os.replace(temporary, path)


def safe_relative(value):
    if not isinstance(value, str): raise ValueError('Path must be a string')
    p = PurePosixPath(value)
    if not isinstance(value, str) or '\\' in value or '\0' in value or p.is_absolute() or any(x in ('..', '.') for x in p.parts) or not p.parts or str(p) != value:
        raise ValueError('Unsafe relative path in catalogue')
    return p


def target_path(root, relative):
    relative = safe_relative(relative)
    relative = PurePosixPath(unicodedata.normalize('NFC', str(relative)))
    root = Path(root).resolve()
    out = root.joinpath(*relative.parts)
    current = out
    while current != root:
        if current.is_symlink():
            raise ValueError('Symlink in source/destination path')
        current = current.parent
    return out


def sql_statements(text):
    """Split SQL without splitting strings, backticks or comments."""
    result, start, quote, comment, i = [], 0, None, None, 0
    while i < len(text):
        c = text[i]
        if comment == 'line':
            if c == '\n': comment = None
        elif comment == 'block':
            if text[i:i+2] == '*/': comment = None; i += 1
        elif quote:
            if c == '\\': i += 1
            elif c == quote:
                if text[i:i+2] == quote*2: i += 1
                else: quote = None
        elif text[i:i+2] == '/*': comment = 'block'; i += 1
        elif c == '#' or (text[i:i+2] == '--' and (i+2 == len(text) or text[i+2].isspace())): comment = 'line'
        elif c in ('"', "'", '`'): quote = c
        elif c == ';': result.append(text[start:i+1]); start = i+1
        i += 1
    if text[start:].strip(): result.append(text[start:])
    return result


def schema_only(text):
    output = []
    for statement in sql_statements(text):
        # Strip dump annotations/host details as well as data statements.
        statement = statement.lstrip()
        while statement.startswith(('--', '#', '/*')):
            if statement.startswith('/*'):
                end=statement.find('*/')
                if end<0:raise ValueError('Unclosed SQL annotation')
                statement=statement[end+2:].lstrip()
            else:
                statement=statement.partition('\n')[2].lstrip()
        if re.match(r'(?is)^(?:CREATE\s+(?:TABLE|(?:UNIQUE\s+)?INDEX)|ALTER\s+TABLE)\b', statement):
            output.append(statement.rstrip(';')+';')
    # Dump order is not dependency order. Disable FK checks only in this import
    # session; the Compose mounts this file solely for an empty database volume.
    return ('-- Schema only: imported data and database deletion commands intentionally omitted.\n\n'
            'SET @IC_PREVIOUS_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;\n'
            'SET FOREIGN_KEY_CHECKS = 0;\n\n'+'\n\n'.join(output)+
            '\n\nSET FOREIGN_KEY_CHECKS = @IC_PREVIOUS_FOREIGN_KEY_CHECKS;\n')


def sanitize(text, relative):
    changes = collections.Counter()
    if relative.endswith('.cfg'):
        kept = []
        for line in text.splitlines(keepends=True):
            if re.match(r'(?i)^\s*(?:(?:set|sets|setr)\s+)?(?:sv_licensekey|steam_webapikey|mysql_connection_string)\b', line):
                changes['runtime_secret_setting'] += 1
                continue
            if re.match(r'(?i)^\s*exec\s+["\']?config/keys\.cfg', line):
                changes['private_keys_reference'] += 1
                continue
            if re.match(r'(?i)^\s*add_(?:principal|ace)\s+identifier\.', line):
                changes['packaged_identity_grant'] += 1
                continue
            if re.match(r'(?i)^\s*set\s+onesync\s+', line):
                changes['onesync_managed_by_txadmin'] += 1
                continue
            kept.append(line)
        text = ''.join(kept)
    for name, pattern in [('cfx_key', CFX), ('webhook', WEBHOOK), ('mysql_uri', MYSQL)]:
        text, count = pattern.subn('', text)
        changes[name] += count
    text, count = SENSITIVE.subn(lambda m: m[1]+m[2]+m[2], text)
    changes['sensitive_assignment'] += count
    return text, {k:v for k,v in changes.items() if v}


def source_files(source):
    for parent, directories, files in os.walk(source, followlinks=False):
        directories[:] = sorted(d for d in directories if d not in SKIP_DIRS and not (Path(parent)/d).is_symlink())
        for name in sorted(files):
            path = Path(parent)/name
            relative = path.relative_to(source)
            if path.is_symlink(): raise ValueError('Source symlinks require explicit review')
            if name in {'.DS_Store', 'Thumbs.db', '.replxx_history', '.gitignore', '.gitattributes'} or name.startswith('.env') or path.suffix.lower() in {'.pem','.key','.pfx','.p12'}: continue
            if relative.parts[0] not in {'resources','config','database'} and relative.as_posix() != 'logo.png': continue
            if relative.as_posix() == 'config/keys.cfg': continue
            if relative.parts[0] == 'database' and path.suffix != '.sql': continue
            yield path, relative.as_posix()


def prepare(source, destination):
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if not (source/'resources').is_dir() or source == destination or source in destination.parents or destination in source.parents: raise ValueError('Invalid/nested source and destination')
    if (destination/'assets.lock.json').exists(): raise ValueError('Catalogue already exists; use a fresh migration destination')
    manifests = {p.parent.relative_to(source).as_posix() for name in ('fxmanifest.lua','__resource.lua') for p in (source/'resources').rglob(name)}
    records, redactions, code_bytes, code_count, asset_bytes = [], [], 0, 0, 0
    print('Inventory, sanitization and SHA-256 generation...', flush=True)
    progress = 0
    for path, relative in source_files(source):
        raw = None
        asset = path.suffix.lower().lstrip('.') in ASSET_EXT or path.name.lower().endswith(('.yft.xml','.ydr.xml','.ytd.xml','.ydd.xml','.ybn.xml'))
        if not asset:
            raw = path.read_bytes()
            try: text = raw.decode('utf-8-sig')
            except UnicodeDecodeError: asset = True
        if asset:
            if not relative.startswith('resources/'):
                # Root logo is small, versioned branding; other non-resource payloads are excluded.
                if relative == 'logo.png':
                    out = target_path(destination, relative); out.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(path, out); os.chmod(out,0o644)
                    code_bytes += path.stat().st_size; code_count += 1
                continue
            parent = PurePosixPath(relative).parent
            while str(parent) not in manifests and str(parent) not in {'resources','.'}: parent = parent.parent
            resource = str(parent)
            size = path.stat().st_size
            records.append({'path':relative,'size':size,'sha256':file_hash(path),'resource':resource,
                            'profile':'full' if any(x in HEAVY for x in PurePosixPath(relative).parts) else 'core'})
            asset_bytes += size
            if asset_bytes-progress >= CHUNK:
                print(f'Hashed {asset_bytes/1024**3:.2f} GiB',flush=True);progress=asset_bytes
            continue
        if path.suffix.lower() == '.sql': text = schema_only(text)
        text, changes = sanitize(text, relative)
        if changes: redactions.append({'path':relative,'changes':changes})
        if relative == 'database/databasedelux.sql': relative = 'database/schema.sql'
        out = target_path(destination, relative)
        if out.exists(): raise ValueError('Refusing to overwrite destination code: '+relative)
        out.parent.mkdir(parents=True, exist_ok=True); data=text.encode()
        out.write_bytes(data);os.chmod(out,0o644);code_bytes+=len(data);code_count+=1
    groups = collections.defaultdict(list)
    for record in records: groups[record['resource']].append(record)
    packages = []
    for resource, files in sorted(groups.items()):
        chunks, current, size = [], [], 0
        for record in sorted(files,key=lambda f:f['path']):
            if current and size+record['size']>CHUNK:chunks.append(current);current=[];size=0
            current.append({k:v for k,v in record.items() if k not in {'resource','profile'}});size+=record['size']
        if current:chunks.append(current)
        for part, chunk in enumerate(chunks):
            identifier=digest(canonical(chunk))
            packages.append({'id':identifier,'resource':resource,'part':part,'profile':files[0]['profile'],
                'bytes':sum(f['size'] for f in chunk),'files':chunk,
                'archive':{'object':f'{PROJECT}/objects/{identifier}.tar.gz','sha256':None,'size':None}})
    lock={'format':1,'project':PROJECT,'provenance':{'source':'User supplied TocadoMago_delux','license':'unverified; private storage only'},
          'packages':packages,'stats':{'resources':len(manifests),'code_files':code_count,'code_bytes':code_bytes,
                                     'asset_files':len(records),'asset_bytes':asset_bytes}}
    save_json(destination/'assets.lock.json',lock)
    save_json(destination/'docs/import-redactions.json',{'format':1,'files':redactions,'note':'Values are never recorded; original source remains untouched.'})
    print(json.dumps(lock['stats']),flush=True)


def validate_lock(lock):
    if lock.get('format')!=1 or lock.get('project')!=PROJECT:raise ValueError('Unsupported catalogue')
    paths, identifiers = set(), set()
    for package in lock['packages']:
        identifier=package['id']
        if not re.fullmatch('[0-9a-f]{64}',identifier) or identifier in identifiers:raise ValueError('Invalid/duplicate package ID')
        identifiers.add(identifier)
        if digest(canonical(package['files']))!=identifier:raise ValueError('Package roster changed')
        if package['archive']['object']!=f'{PROJECT}/objects/{identifier}.tar.gz':raise ValueError('Invalid object path')
        if package['profile'] not in {'core','full'}:raise ValueError('Unknown profile')
        for entry in package['files']:
            path=safe_relative(entry['path'])
            normalized = unicodedata.normalize('NFC', str(path))
            if path.parts[0]!='resources' or normalized in paths:raise ValueError('Invalid/duplicate asset path')
            paths.add(normalized)
            if not re.fullmatch('[0-9a-f]{64}',entry['sha256']) or type(entry['size'])!=int or entry['size']<0:raise ValueError('Invalid file record')
    return lock


def write_archive(package, source, output):
    with gzip.GzipFile(fileobj=output,mode='wb',compresslevel=1,mtime=0,filename='') as gz:
        with tarfile.open(fileobj=gz,mode='w|',format=tarfile.PAX_FORMAT) as archive:
            for record in package['files']:
                path=target_path(source,record['path'])
                if path.stat().st_size!=record['size']:raise ValueError('Source changed after inventory')
                member=tarfile.TarInfo(record['path']);member.size=record['size'];member.mode=0o644;member.mtime=0
                with path.open('rb') as stream:archive.addfile(member,stream)


def verify_archive(path, package, destination=None):
    expected={f['path']:f for f in package['files']};seen=set()
    with tarfile.open(path,'r:gz') as archive:
        for member in archive:
            if not member.isfile() or member.name not in expected or member.name in seen:raise ValueError('Unexpected archive member')
            safe_relative(member.name);record=expected[member.name]
            if member.size!=record['size']:raise ValueError('Archive member size mismatch')
            h=hashlib.sha256()
            with archive.extractfile(member) as stream:
                for block in iter(lambda:stream.read(1024**2),b''):h.update(block)
            if h.hexdigest()!=record['sha256']:raise ValueError('Archive member hash mismatch')
            seen.add(member.name)
        if seen!=set(expected):raise ValueError('Incomplete archive')
        if destination:
            # All members were validated before the first write. No extractall/path traversal.
            for record in package['files']:
                out=target_path(destination,record['path'])
                if out.exists():
                    if file_hash(out)!=record['sha256']:raise ValueError('Refusing to overwrite a modified asset')
                    continue
                out.parent.mkdir(parents=True,exist_ok=True)
                member=archive.getmember(record['path'])
                fd,name=tempfile.mkstemp(prefix='.asset-part-',dir=out.parent);temp=Path(name)
                try:
                    with os.fdopen(fd,'wb') as tmp:
                        with archive.extractfile(member) as src:shutil.copyfileobj(src,tmp,1024**2)
                    os.chmod(temp,0o644);os.replace(temp,out)
                finally:temp.unlink(missing_ok=True)


# Sent over SSH as our own program; supplied game code is never executed remotely.
REMOTE = r'''
import sys,os,json,hashlib,tempfile,tarfile,pathlib,re
os.umask(0o077)
root=pathlib.Path(sys.argv[1]);action=sys.argv[2];meta=json.loads(sys.stdin.buffer.readline());identifier=meta['id']
if not re.fullmatch('[0-9a-f]{64}',identifier):raise ValueError('invalid ID')
directory=root/'tocado-mago'/'objects';directory.mkdir(parents=True,exist_ok=True,mode=0o700)
if directory.is_symlink():raise ValueError('symlink store')
final=directory/(identifier+'.tar.gz');receipt=directory/(identifier+'.json')
if action=='status':
 print(receipt.read_text() if final.is_file() and receipt.is_file() else 'null');sys.exit(0)
if final.exists() or receipt.exists():raise ValueError('immutable object already exists')
fd,name=tempfile.mkstemp(prefix='.'+identifier,dir=directory);h=hashlib.sha256();size=0
try:
 with os.fdopen(fd,'wb') as out:
  while True:
   b=sys.stdin.buffer.read(1024*1024)
   if not b:break
   out.write(b);h.update(b);size+=len(b)
  out.flush();os.fsync(out.fileno())
 expected={f['path']:f for f in meta['files']};seen=set()
 with tarfile.open(name,'r:gz') as tar:
  for member in tar:
   if not member.isfile() or member.name not in expected or member.name in seen:raise ValueError('unexpected archive member')
   rec=expected[member.name]
   if member.size!=rec['size']:raise ValueError('size mismatch')
   fh=hashlib.sha256()
   with tar.extractfile(member) as stream:
    for b in iter(lambda:stream.read(1024*1024),b''):fh.update(b)
   if fh.hexdigest()!=rec['sha256']:raise ValueError('file hash mismatch')
   seen.add(member.name)
 if seen!=set(expected):raise ValueError('incomplete package')
 result={'id':identifier,'sha256':h.hexdigest(),'size':size,'files':len(expected)}
 os.chmod(name,0o600);os.rename(name,final)
 fd,tmp=tempfile.mkstemp(prefix='.receipt-',dir=directory)
 with os.fdopen(fd,'w') as out:json.dump(result,out);out.flush();os.fsync(out.fileno())
 os.chmod(tmp,0o600);os.rename(tmp,receipt);print(json.dumps(result))
except BaseException:
 if os.path.exists(name):os.unlink(name)
 raise
'''


def parse_store(value):
    if not value:raise ValueError('Set ASSET_STORE or provide --store (SSH destination or local private directory)')
    if ':' not in value:return None,Path(value).expanduser().resolve()
    host,root=value.split(':',1)
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_.-]*@[A-Za-z0-9_][A-Za-z0-9_.-]*',host) or not root.startswith('/') or '..' in PurePosixPath(root).parts:
        raise ValueError('Use user@host:/absolute/path for the SSH store')
    return host,root


def ssh_command(host,root,action):
    return ['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10',host,shlex.join(['python3','-c',REMOTE,str(root),action])]


def publish(lock_path, source, store):
    lock_path=Path(lock_path);lock=validate_lock(json.loads(lock_path.read_text()));host,root=parse_store(store)
    for index,package in enumerate(lock['packages'],1):
        started=time.monotonic();header=canonical({'id':package['id'],'files':package['files']})+b'\n'
        if host:
            p=subprocess.run(ssh_command(host,root,'status'),input=header,capture_output=True,check=True)
            receipt=json.loads(p.stdout)
            if not receipt:
                with tempfile.TemporaryFile() as err:
                    proc=subprocess.Popen(ssh_command(host,root,'put'),stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=err)
                    try:
                        proc.stdin.write(header);write_archive(package,source,proc.stdin);proc.stdin.close()
                        response=proc.stdout.read();code=proc.wait()
                        if code:raise RuntimeError('Remote package validation/upload failed')
                        receipt=json.loads(response)
                    finally:
                        if proc.poll() is None:proc.terminate();proc.wait()
        else:
            final=root/package['archive']['object'];meta=final.with_suffix('.json')
            final.parent.mkdir(parents=True,exist_ok=True)
            if final.exists():
                receipt=json.loads(meta.read_text())
                if file_hash(final)!=receipt['sha256']:raise ValueError('Stored archive is corrupt')
            else:
                with tempfile.NamedTemporaryFile(dir=final.parent,delete=False) as out:
                    write_archive(package,source,out);tmp=Path(out.name)
                try:verify_archive(tmp,package);os.replace(tmp,final)
                finally:
                    if tmp.exists():tmp.unlink()
                receipt={'id':package['id'],'sha256':file_hash(final),'size':final.stat().st_size,'files':len(package['files'])}
                save_json(meta,receipt)
        if receipt['id']!=package['id']:raise ValueError('Receipt ID mismatch')
        if package['archive']['sha256'] and package['archive']['sha256']!=receipt['sha256']:raise ValueError('Immutable archive hash changed')
        package['archive'].update({k:receipt[k] for k in ['sha256','size']});save_json(lock_path,lock)
        print(f"[{index}/{len(lock['packages'])}] {package['resource']} part {package['part']}: {package['bytes']/1024**2:.1f} MiB verified ({time.monotonic()-started:.1f}s)",flush=True)
    seal_catalog(lock_path,store)


def seal_catalog(lock_path, store):
    data=Path(lock_path).read_bytes();lock=validate_lock(json.loads(data))
    if any(not p['archive']['sha256'] for p in lock['packages']):raise ValueError('Catalogue contains unpublished packages')
    identifier=digest(data);host,root=parse_store(store)
    if host:
        program=r'''
import sys,pathlib,hashlib,os,tempfile
os.umask(0o077)
root=pathlib.Path(sys.argv[1]);expected=sys.argv[2];data=sys.stdin.buffer.read()
if hashlib.sha256(data).hexdigest()!=expected:raise ValueError('catalogue checksum mismatch')
directory=root/'tocado-mago'/'catalogs';directory.mkdir(parents=True,exist_ok=True,mode=0o700)
if directory.is_symlink():raise ValueError('symlink catalogue directory')
out=directory/(expected+'.json')
if out.exists():
 if hashlib.sha256(out.read_bytes()).hexdigest()!=expected:raise ValueError('immutable catalogue is corrupt')
else:
 fd,tmp=tempfile.mkstemp(prefix='.catalog-',dir=directory)
 with os.fdopen(fd,'wb') as stream:stream.write(data);stream.flush();os.fsync(stream.fileno())
 os.chmod(tmp,0o600);os.rename(tmp,out)
print(expected)
'''
        cmd=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10',host,shlex.join(['python3','-c',program,str(root),identifier])]
        result=subprocess.run(cmd,input=data,capture_output=True,check=True)
        if result.stdout.decode().strip()!=identifier:raise ValueError('Catalogue receipt mismatch')
    else:
        out=root/PROJECT/'catalogs'/(identifier+'.json');out.parent.mkdir(parents=True,exist_ok=True)
        if out.exists() and file_hash(out)!=identifier:raise ValueError('Immutable catalogue is corrupt')
        if not out.exists():out.write_bytes(data);os.chmod(out,0o600)
    print('Sealed catalogue:',identifier,flush=True)
    return identifier


def selected(lock, profile):
    return [p for p in lock['packages'] if profile=='full' or p['profile']=='core']


def asset_aliases(lock_path, lock, profile):
    """Reuse already-admitted, hash-locked media under independent resource paths."""
    config=Path(lock_path).parent/'config/asset-aliases.json'
    if not config.exists(): return []
    if config.is_symlink(): raise ValueError('Asset alias configuration cannot be a symlink')
    aliases=json.loads(config.read_text())
    if not isinstance(aliases,list): raise ValueError('Invalid asset aliases')
    records=[f for package in selected(lock,profile) for f in package['files']]
    destinations=set();result=[]
    for entry in aliases:
        path=str(safe_relative(entry['destination']))
        if PurePosixPath(path).suffix.lower() not in {'.png','.jpg','.jpeg','.webp','.svg','.ogg','.wav','.mp3'}: raise ValueError('Aliases are restricted to media assets')
        if not path.startswith('resources/') or path in destinations: raise ValueError('Invalid/duplicate alias destination')
        destinations.add(path)
        sources=[f for f in records if f['sha256']==entry['sha256'] and f['size']==entry['size']]
        if not sources: raise ValueError('Asset alias must reference an admitted asset in this profile')
        if any(f['path']==path for f in records): raise ValueError('Asset alias cannot replace a catalogue path')
        result.append((sources[0],entry))
    return result


def install_aliases(lock_path,lock,destination,profile):
    for source,alias in asset_aliases(lock_path,lock,profile):
        src=target_path(destination,source['path']);out=target_path(destination,alias['destination'])
        if not src.is_file() or file_hash(src)!=source['sha256']: raise ValueError('Alias source failed integrity check')
        if out.exists():
            if not out.is_file() or file_hash(out)!=alias['sha256']: raise ValueError('Modified asset alias requires explicit review')
            continue
        out.parent.mkdir(parents=True,exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=out.parent,delete=False) as stream:
            temporary=Path(stream.name)
            try:
                with src.open('rb') as value: shutil.copyfileobj(value,stream,1024**2)
                stream.flush()
                if file_hash(temporary)!=alias['sha256']: raise ValueError('Alias copy failed integrity check')
                os.chmod(temporary,0o644);os.replace(temporary,out)
            finally:temporary.unlink(missing_ok=True)


def verify(lock_path, destination, profile):
    lock=validate_lock(json.loads(Path(lock_path).read_text()));count=0
    for package in selected(lock,profile):
        for record in package['files']:
            out=target_path(destination,record['path'])
            if not out.is_file() or out.stat().st_size!=record['size'] or file_hash(out)!=record['sha256']:raise ValueError('Missing/modified asset: '+record['path'])
            count+=1
    for _,alias in asset_aliases(lock_path,lock,profile):
        out=target_path(destination,alias['destination'])
        if not out.is_file() or out.stat().st_size!=alias['size'] or file_hash(out)!=alias['sha256']: raise ValueError('Missing/modified asset alias')
        count+=1
    print(f'Verified {count} installed asset files ({profile})')


def sync(lock_path, destination, profile, store):
    lock=validate_lock(json.loads(Path(lock_path).read_text()));packages=selected(lock,profile);destination=Path(destination).resolve()
    host,root=parse_store(store)
    missing=0
    for package in packages:
        if not package['archive']['sha256']:raise ValueError('Package has not been published')
        for record in package['files']:
            out=target_path(destination,record['path'])
            if out.exists():
                if file_hash(out)!=record['sha256']:raise ValueError('Modified asset requires explicit review; not overwritten')
            else:missing+=record['size']
    reserve=max((p['archive']['size'] or 0 for p in packages),default=0)+1024**3
    if shutil.disk_usage(destination).free<missing+reserve:raise ValueError('Not enough physical free space for profile, temporary archive and 1 GiB reserve')
    tempdir=destination/'.assets-cache';tempdir.mkdir(exist_ok=True)
    for index,package in enumerate(packages,1):
        if all(target_path(destination,f['path']).is_file() for f in package['files']):continue
        with tempfile.NamedTemporaryFile(dir=tempdir,delete=False) as output:
            tmp=Path(output.name)
            try:
                if host:
                    remote=str(PurePosixPath(root)/package['archive']['object'])
                    cmd=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10',host,shlex.join(['cat','--',remote])]
                    subprocess.run(cmd,stdout=output,check=True)
                else:
                    with (root/package['archive']['object']).open('rb') as source:shutil.copyfileobj(source,output,1024**2)
                output.flush()
                if tmp.stat().st_size!=package['archive']['size'] or file_hash(tmp)!=package['archive']['sha256']:raise ValueError('Archive checksum mismatch')
                verify_archive(tmp,package,destination)
            finally:tmp.unlink(missing_ok=True)
        print(f'Installed package {index}/{len(packages)}',flush=True)
    install_aliases(lock_path,lock,destination,profile)
    verify(lock_path,destination,profile)
    save_json(destination/'.assets-state.json',{'lock_sha256':file_hash(lock_path),'profile':profile})


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    subs=parser.add_subparsers(dest='command',required=True)
    p=subs.add_parser('prepare');p.add_argument('--source',required=True);p.add_argument('--destination',required=True)
    for command in ['publish','seal','sync','verify']:
        p=subs.add_parser(command);p.add_argument('--lock',default='assets.lock.json')
        if command=='publish':p.add_argument('--source',required=True)
        elif command!='seal':p.add_argument('--destination',default='.');p.add_argument('--profile',choices=['core','full'],default='core')
        if command!='verify':
            local_config=Path('.assets-store.json')
            configured=json.loads(local_config.read_text()).get('store') if local_config.exists() else None
            p.add_argument('--store',default=os.environ.get('ASSET_STORE') or configured)
    args=parser.parse_args()
    if args.command=='prepare':prepare(args.source,args.destination)
    elif args.command=='publish':publish(args.lock,args.source,args.store)
    elif args.command=='seal':seal_catalog(args.lock,args.store)
    elif args.command=='sync':sync(args.lock,args.destination,args.profile,args.store)
    else:verify(args.lock,args.destination,args.profile)


if __name__=='__main__':
    try:main()
    except (ValueError,OSError,subprocess.CalledProcessError,RuntimeError,tarfile.TarError) as error:
        print(f'Asset operation failed: {type(error).__name__}: {error}',file=sys.stderr);sys.exit(1)
