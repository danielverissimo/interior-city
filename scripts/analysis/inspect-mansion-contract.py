#!/usr/bin/env python3
"""Inert reader for the supplied Lua carrier; emits only allowlisted ABI facts.

This parses data, never Lua code. No functions from the target are executed and
no license flag, runtime branch, executable or network setting is modified.
"""
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

EXPECTED='e5bae65aa5852c5b4a161fb9aa0308d2772fec05bbd6e9da551ab205da22578c'
ALLOW={'getMansions','saveMansion','removeMansion','checkAccessByMansionId','checkAccessByPermission'}

def inspect(path):
    raw=path.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=EXPECTED:raise ValueError('Unsupported artifact identity')
    match=re.search(rb'VMCall\("([^"\n]+)"\s*,GetFEnv\(\)',raw)
    if not match:raise ValueError('Carrier not found')
    carrier=match[1][4:].decode('ascii')
    decoded=bytearray();repeat=None
    for offset in range(0,len(carrier),2):
        pair=carrier[offset:offset+2]
        if len(pair)!=2:raise ValueError('Incomplete carrier')
        if pair[1]=='Q':repeat=int(pair[0])
        else:decoded.extend(bytes([int(pair,16)])*(repeat if repeat is not None else 1));repeat=None
    if len(decoded)!=87401 or hashlib.sha256(decoded).hexdigest()!='f23c2e3875ed60963bf7f3b29987feda99763b14ac8a68ba0e0b07f6c7cc9666':raise ValueError('Decoded identity mismatch')
    cursor=0;prototypes=[]
    def read(fmt):
        nonlocal cursor
        width=struct.calcsize(fmt)
        if cursor+width>len(decoded):raise ValueError('Incomplete data')
        value=struct.unpack_from(fmt,decoded,cursor)[0];cursor+=width;return value
    def parse(name):
        nonlocal cursor
        start=cursor;constants=[None]
        for _ in range(read('<I')):
            kind=read('<B')
            if kind==1:value=bool(read('<B'))
            elif kind==2:value=read('<d')
            elif kind==3:
                length=read('<I')
                if cursor+length>len(decoded):raise ValueError('Incomplete string')
                value=bytes(decoded[cursor:cursor+length]).decode('utf-8',errors='replace');cursor+=length
            else:value=None
            constants.append(value)
        params=read('<B');instructions=[]
        for _ in range(read('<I')):
            descriptor=read('<B')
            if descriptor&1:instructions.append(None);continue
            kind=(descriptor>>1)&3;mask=(descriptor>>3)&7
            row=[read('<H'),read('<H'),None,None]
            if kind==0:row[2]=read('<H');row[3]=read('<H')
            elif kind==1:row[2]=read('<I')
            elif kind==2:row[2]=read('<I')-65536
            else:row[2]=read('<I')-65536;row[3]=read('<H')
            for index in range(3):
                if mask&(1<<index):
                    key=row[index+1]
                    if type(key)is not int or not 0<=key<len(constants):raise ValueError('Invalid constant reference')
                    row[index+1]=constants[key]
            instructions.append(row)
        item={'name':name,'params':params,'instructions':instructions,'start':start}
        prototypes.append(item)
        children=read('<I')
        for index in range(children):parse(name+'.'+str(index))
        item['end']=cursor
    parse('root')
    if cursor!=len(decoded) or len(prototypes)!=86:raise ValueError('Coverage mismatch')
    root=prototypes[0]['instructions'];bindings=[]
    for index,row in enumerate(root):
        if not row or row[0]!=241 or row[2]!='MG_MANSIONS_REGISTER_EXPORT':continue
        name=None;prototype=None
        for candidate in root[index+1:index+12]:
            if not candidate:continue
            if candidate[0]==3 and candidate[2] in ALLOW:name=candidate[2]
            if candidate[0]==136:prototype=candidate[2]
            if candidate[0]==59:break
        if name and type(prototype)is int:
            target=next((p for p in prototypes if p['name']=='root.'+str(prototype)),None)
            if not target:raise ValueError('Unresolved closure')
            bindings.append({'export':name,'prototype':target['name'],'parameters':target['params'],
                             'decodedRange':[target['start'],target['end']],'registrationInstruction':index+1})
    required={'getMansions','saveMansion','removeMansion'}
    if not required<={row['export']for row in bindings}:raise ValueError('Required ABI not resolved')
    return {'producer':'inert-python-carrier-reader','sourceSha256':EXPECTED,
            'decodedSha256':hashlib.sha256(decoded).hexdigest(),'decodedBytes':len(decoded),
            'prototypes':len(prototypes),'exhausted':True,'targetExecuted':False,'bindings':bindings,
            'limits':['Static ABI only; no runtime execution or equivalence proof.',
                      'Authentication and unrelated constants are not emitted.']}

if __name__=='__main__':
    try:print(json.dumps(inspect(Path(sys.argv[1])),indent=2,ensure_ascii=False))
    except (ValueError,OSError,IndexError,TypeError,struct.error):
        print('Static inspection refused; artifact or carrier differs from the inspected version.',file=sys.stderr)
        raise SystemExit(1)
