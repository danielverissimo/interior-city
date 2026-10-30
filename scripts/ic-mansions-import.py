#!/usr/bin/env python3
"""Validate a stopped legacy mansion snapshot and prepare NEW independent state.

No game, database, group, inventory, money or network operation is performed.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import os
import sys

class ImportError(ValueError):
    pass

def safe_path(path):
    if not path.is_absolute() or '..' in path.parts or any(p.is_symlink() for p in (path,*path.parents)):
        raise ImportError('Use absolute paths without symlinks or parent traversal')
    return path

def read(path):
    safe_path(path)
    if not path.is_file() or path.stat().st_size>16000000:raise ImportError('Input missing or exceeds limit')
    raw=path.read_bytes()
    try:value=json.loads(raw,parse_constant=lambda _:(_ for _ in ()).throw(ValueError()))
    except (ValueError,UnicodeError):raise ImportError('Invalid JSON; values suppressed') from None
    return raw,value

def integer(value,minimum=0):
    if type(value) is not int or value<minimum or value>9007199254740991:raise ImportError('Invalid integer')
    return value

def text(value):
    if not isinstance(value,str) or not value or len(value)>160 or any(ord(c)<32 for c in value):raise ImportError('Invalid identifier')
    return value

def coords(value):
    if not isinstance(value,dict):raise ImportError('Invalid coordinates')
    for key in ('x','y','z'):
        number=value.get(key)
        if type(number) not in (int,float) or not math.isfinite(number) or abs(number)>1000000:raise ImportError('Invalid coordinates')

def validate(document,catalog):
    if not isinstance(document,dict) or document.get('version')!=1 or not isinstance(document.get('mansions'),list):raise ImportError('Unsupported mansion schema')
    if not isinstance(catalog,dict) or not isinstance(catalog.get('items'),list):raise ImportError('Unsupported furniture catalog')
    items={}
    for item in catalog['items']:
        if not isinstance(item,dict):raise ImportError('Invalid catalog item')
        key=text(item.get('id'));text(item.get('model'));text(item.get('name'));text(item.get('category'));integer(item.get('price'))
        if key in items and (item['model'],item['price'])!=(items[key]['model'],items[key]['price']):raise ImportError('Conflicting catalog identity')
        items.setdefault(key,{field:item[field] for field in ('id','name','model','category','price')})
    ids,groups,permissions=set(),set(),set()
    stats={'mansions':0,'occupied':0,'residents':0,'furniture':0}
    for mansion in document['mansions']:
        if not isinstance(mansion,dict):raise ImportError('Invalid mansion record')
        key=text(mansion.get('id'));group=text(mansion.get('group'));text(mansion.get('permission'));text(mansion.get('name'))
        permission=mansion['permission']
        if key in ids or group.casefold() in groups or permission in permissions:raise ImportError('Duplicate mansion/group/permission identity')
        ids.add(key);groups.add(group.casefold());permissions.add(permission)
        coords(mansion.get('purchaseCoords'))
        for field in ('price','iptuValue'):integer(mansion.get(field))
        integer(mansion.get('maxResidents'),1)
        owner=mansion.get('ownerId')
        if owner is not None:integer(owner,1)
        members=mansion.get('members',[])
        if not isinstance(members,list) or len(set(members))!=len(members):raise ImportError('Invalid resident list')
        for member in members:integer(member,1)
        if owner in members or (owner is None and members):raise ImportError('Invalid owner/resident relationship')
        if (1 if owner else 0)+len(members)>mansion['maxResidents']:raise ImportError('Residents exceed configured capacity')
        for field in ('purchasedAt','createdAt','updatedAt','iptuPaidUntil','lastIptuPaidAt'):
            if mansion.get(field) is not None:integer(mansion[field])
        for field in ('chest','garage'):
            part=mansion.get(field)
            if not isinstance(part,dict) or type(part.get('enabled')) is not bool:raise ImportError('Invalid dependent configuration')
            if part['enabled']:coords(part.get('coords'))
        chest,garage=mansion['chest'],mansion['garage']
        if chest['enabled']:
            if type(chest.get('weight')) not in (int,float) or not math.isfinite(chest['weight']) or chest['weight']<0:raise ImportError('Invalid chest capacity')
            text(chest.get('name'))
        if garage['enabled']:
            text(garage.get('id'));text(garage.get('type'))
            if type(garage.get('blipDistance')) not in (int,float) or not math.isfinite(garage['blipDistance']) or garage['blipDistance']<=0:raise ImportError('Invalid garage marker distance')
            spawns=garage.get('spawnCoords')
            if not isinstance(spawns,list) or not 1<=len(spawns)<=100:raise ImportError('Invalid garage spawn list')
            for spawn in spawns:
                coords(spawn)
                if type(spawn.get('w')) not in (int,float) or not math.isfinite(spawn['w']):raise ImportError('Invalid garage direction')
        doors=mansion.get('doors',[])
        if not isinstance(doors,list):raise ImportError('Invalid doors')
        for door in doors:
            coords(door)
            if type(door.get('hash')) is not int:raise ImportError('Invalid door model')
        pieces=mansion.get('furniture',[])
        if not isinstance(pieces,list):raise ImportError('Invalid furniture state')
        piece_ids=set()
        for piece in pieces:
            if not isinstance(piece,dict):raise ImportError('Invalid furniture record')
            piece_id=text(str(piece.get('id','')))
            if piece_id in piece_ids:raise ImportError('Duplicate furniture identity')
            piece_ids.add(piece_id);coords(piece)
            text(piece.get('model'));text(piece.get('itemId'));integer(piece.get('paidPrice'))
            heading=piece.get('heading')
            if type(heading) not in (int,float) or not math.isfinite(heading):raise ImportError('Invalid furniture direction')
        stats['mansions']+=1;stats['occupied']+=int(owner is not None)
        stats['residents']+=(1 if owner else 0)+len(members);stats['furniture']+=len(pieces)
    return stats,{'version':1,'items':list(items.values())}

def prepare(source,output,*,apply=False,writers_stopped=False):
    safe_path(source);safe_path(output)
    if output.exists():raise ImportError('Output must be a new directory')
    mansion_raw,document=read(source/'mansions.json')
    catalog_raw,catalog=read(source/'furniture_catalog.json')
    stats,normalized_catalog=validate(document,catalog)
    # Preserve all original records and dates verbatim; no renewal or deliveries.
    state=dict(document,operations={},catalogPrices={item['id']:item['price'] for item in normalized_catalog['items']})
    payload=json.dumps(state,ensure_ascii=False,separators=(',',':'))
    checksum=2166136261
    for byte in payload.encode():checksum=((checksum^byte)*16777619)&0xffffffff
    envelope={'generation':1,'state':state,'payload':payload,'checksum':f'{checksum:08x}'}
    encoded=(json.dumps(envelope,ensure_ascii=False,separators=(',',':'))+'\n').encode()
    normalized=(json.dumps(normalized_catalog,ensure_ascii=False,indent=2)+'\n').encode()
    inputs={'mansions.json':hashlib.sha256(mansion_raw).hexdigest(),
            'furniture_catalog.json':hashlib.sha256(catalog_raw).hexdigest()}
    payloads={'state-a.json':encoded,'state-b.json':encoded,'catalog.json':normalized}
    manifest={'version':1,'inputSha256':inputs,'files':{name:hashlib.sha256(raw).hexdigest() for name,raw in payloads.items()},'counts':stats}
    result=dict(stats,catalogItems=len(normalized_catalog['items']),applied=False)
    if not apply:return result
    if not writers_stopped:raise ImportError('Apply requires writers-stopped')
    output.mkdir(mode=0o700)
    try:
        for name,raw in payloads.items():
            with (output/name).open('xb') as stream:os.chmod(output/name,0o600);stream.write(raw)
        with (output/'manifest.json').open('x') as stream:
            os.chmod(output/'manifest.json',0o600);json.dump(manifest,stream,sort_keys=True);stream.write('\n')
    except BaseException:
        # Keep an incomplete private copy for diagnosis; manifest absence prevents use.
        raise
    result['applied']=True
    return result

def verify(output):
    _,manifest=read(output/'manifest.json')
    expected={'state-a.json','state-b.json','catalog.json'}
    if not isinstance(manifest,dict) or set(manifest.get('files',{}))!=expected:raise ImportError('Invalid import manifest')
    for name in expected:
        raw,_=read(output/name)
        if hashlib.sha256(raw).hexdigest()!=manifest['files'][name]:raise ImportError('Snapshot has changed; never overwrite active state to remove drift')
    return {'verified':True,'files':3}

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('command',choices=('prepare','verify'))
    p.add_argument('--source',type=Path)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--apply',action='store_true');p.add_argument('--writers-stopped',action='store_true')
    args=p.parse_args(argv)
    if args.command=='verify':result=verify(args.output)
    else:
        if not args.source:p.error('prepare requires --source')
        result=prepare(args.source,args.output,apply=args.apply,writers_stopped=args.writers_stopped)
    print(json.dumps(result,sort_keys=True));return result

if __name__=='__main__':
    try:main()
    except (ImportError,OSError,ValueError,TypeError,KeyError):
        print('Import refused. Check effective input schema, private permissions, stopped writers and a new output directory; values suppressed.',file=sys.stderr)
        raise SystemExit(1)
