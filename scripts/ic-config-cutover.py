#!/usr/bin/env python3
"""Explicit IC Config/mansion installation, state preservation and runtime checks.

Does not connect to a host, stop services or execute supplier game resources.
The installer invokes prepare only AFTER stopping writers and taking a backup.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import types
import urllib.request
sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent

class CutoverError(ValueError):pass

def safe(path):
    if not path.is_absolute()or '..'in path.parts or any(p.is_symlink()for p in(path,*path.parents)):
        raise CutoverError('Operational paths must be absolute and must not use symlinks')
    return path

def load(filename,name):
    path=HERE/filename
    module=types.ModuleType(name);module.__file__=str(path)
    exec(compile(path.read_text(),str(path),'exec'),module.__dict__)
    return module

def run(args,input=None,timeout=180):
    result=subprocess.run(args,input=input,text=True,capture_output=True,timeout=timeout)
    if result.returncode:raise CutoverError('Operational command failed; private diagnostics suppressed')
    return result.stdout.rstrip('\r\n')

def write(path,value):
    path=safe(Path(path))
    temporary=path.with_name(path.name+'.next')
    with temporary.open('x')as stream:
        os.chmod(temporary,0o600);json.dump(value,stream,sort_keys=True,ensure_ascii=False,indent=2);stream.write('\n')
    temporary.replace(path)

def modules():return load('ic-config-state.py','config_state'),load('ic-mansions-import.py','mansion_import')

def runtime_cfg():
    return ('# Rendered by explicit --ic-config-cutover before sealing the candidate.\n'
            'setr ic_mansions_resource "ic_mansions"\nset ic_mansions_enabled "true"\n'
            'set ic_config_enabled "true"\nset ic_config_writes_enabled "true"\n'
            'setr ic_config_legacy_aliases "true"\n')

def configure_candidate(release):
    resources=release/'config/resources.cfg';config=release/'config/config.cfg'
    original=resources.read_text();cfg=config.read_text()
    for old,new in (('m_mansions','ic_mansions'),('mg_config_panel','ic_config')):
        pattern=r'(?m)^\s*(?:ensure|start)\s+'+old+r'\s*$'
        own=r'(?m)^\s*(?:ensure|start)\s+'+new+r'\s*$'
        if len(re.findall(pattern,original))==1 and not re.search(own,original):
            original=re.sub(pattern,'ensure '+new,original)
        elif re.search(pattern,original)or len(re.findall(own,original))!=1:
            raise CutoverError('Unexpected resource selection; candidate was not changed')
    directive='exec config/ic_config_runtime.cfg'
    if directive not in cfg:
        if cfg.count('exec config/resources.cfg')!=1:raise CutoverError('Unknown resource bootstrap')
        cfg=cfg.replace('exec config/resources.cfg',directive+'\nexec config/resources.cfg')
    target=release/'config/ic_config_runtime.cfg'
    if target.exists()and target.read_text()!=runtime_cfg():raise CutoverError('Candidate runtime switches differ')
    resources.write_text(original);config.write_text(cfg);target.write_text(runtime_cfg())
    validate_candidate(release)
    return {'candidateConfigured':True,'services':['ic_config','ic_mansions']}

def validate_candidate(release):
    text=(release/'config/resources.cfg').read_text();cfg=(release/'config/config.cfg').read_text()
    for name in ('m_mansions','mg_config_panel'):
        if re.search(r'(?m)^\s*(?:ensure|start)\s+'+name+r'\s*$',text):raise CutoverError('Legacy resource still selected')
    for name in ('ic_config','ic_mansions'):
        if len(re.findall(r'(?m)^\s*ensure\s+'+name+r'\s*$',text))!=1:raise CutoverError('Own resource selection missing or duplicated')
    if 'exec config/ic_config_runtime.cfg'not in cfg or cfg.index('exec config/ic_config_runtime.cfg')>cfg.index('exec config/resources.cfg'):
        raise CutoverError('Provider switches must load before resources')
    if (release/'config/ic_config_runtime.cfg').read_text()!=runtime_cfg():raise CutoverError('Unexpected provider switches')

def check_previous(root,previous,allow_admin=False):
    states,_=modules();helper=load('release.py','release_check')
    states.safe_path(previous)
    expected=json.loads((root/'state/manifests'/(previous.name+'.json')).read_text())
    actual=helper.inventory(previous)
    allowed=set(states.FILES)|{'resources/[scriptcore]/m_mansions/furniture_catalog.json'}
    if allow_admin:
        migration=load('ic-admin-migrate.py','admin_state')
        allowed|={'resources/[scriptcore]/m_paineladm_v2/'+name for name in (*migration.FILES,'logs_config.json')}
    changed={key for key in set(expected)|set(actual)if expected.get(key)!=actual.get(key)}
    caches={p for p in changed if re.fullmatch(r'scripts/__pycache__/release\.cpython-\d+\.pyc',p)and p not in expected}
    if changed-allowed-caches:raise CutoverError('Immutable release drift requires review')
    for relative in changed-caches:
        if relative not in actual or relative not in expected:raise CutoverError('Mutable files cannot be added or removed by cutover')
        if relative in states.FILES:states.read_json(previous/relative,states.FILES[relative])
        elif relative.endswith('furniture_catalog.json'):states.read_json(previous/relative,dict)
        else:states.read_json(previous/relative)
    return {'previousRelease':previous.name,'reviewedMutableFiles':sorted(changed-caches),'generatedCacheFiles':len(caches)}

def container_info():
    ids=run(['docker','ps','-a','--filter','label=com.docker.compose.project=interior-city-tocado',
             '--filter','label=com.docker.compose.service=fxserver','-q']).splitlines()
    if len(ids)!=1:raise CutoverError('Select exactly one managed FXServer container')
    result=json.loads(run(['docker','inspect',ids[0]]))
    if len(result)!=1:raise CutoverError('Unexpected FXServer inventory')
    return ids[0],result[0]

def stopped_writers():
    container,info=container_info()
    if info['State']['Running']is not False:raise CutoverError('FXServer writers must actually be stopped')
    return container,info.get('Mounts',[])

def source_file(root,previous,relative,mounts):
    target='/server-data/'+relative
    matches=[m for m in mounts if target==m.get('Destination')or target.startswith(m.get('Destination','').rstrip('/')+'/')]
    if matches:
        chosen=max(matches,key=lambda m:len(m['Destination']))
        suffix=target[len(chosen['Destination']):].lstrip('/')
        path=Path(chosen['Source'])/suffix if suffix else Path(chosen['Source'])
    else:path=previous/relative
    safe=load('ic-config-state.py','safe_source');safe.safe_path(path)
    if path!=previous and previous not in path.parents and root/'state/resources'not in path.parents:
        raise CutoverError('Unexpected authoritative resource mount')
    if not path.is_file():raise CutoverError('Authoritative resource configuration missing')
    return path

def persistent_path(root,relative):
    if relative=='resources/[vrp]/vrp/cfg/groups.json':return root/'state/resources/vrp/groups.json'
    if relative=='resources/[scripts]/m_desmanche/config.json':return root/'state/resources/m_desmanche/config.json'
    return root/'state/resources/ic_config/data'/relative

def state_envelope(raw):
    value=json.loads(raw)
    state=value.get('state');payload=value.get('payload')
    if type(value.get('generation'))is not int or value['generation']<0 or not isinstance(state,dict)or state.get('version')!=1:
        raise CutoverError('Own mansion state is incompatible')
    if not isinstance(state.get('mansions'),list)or not isinstance(state.get('operations'),dict)or not isinstance(state.get('catalogPrices'),dict):
        raise CutoverError('Own mansion state is incompatible')
    if payload is None:
        if value['generation']!=0:raise CutoverError('Unsealed own state')
    else:
        checksum=2166136261
        if not isinstance(payload,str):raise CutoverError('Invalid own state payload')
        for byte in payload.encode():checksum=((checksum^byte)*16777619)&0xffffffff
        if value.get('checksum')!=f'{checksum:08x}'or json.loads(payload)!=state:raise CutoverError('Own state checksum differs')
    return value

def own_state(payloads,importer):
    base='resources/[scriptcore]/ic_mansions/'
    a=state_envelope(payloads[base+'state-a.json']);b=state_envelope(payloads[base+'state-b.json'])
    if a['generation']==b['generation']and a['state']!=b['state']:raise CutoverError('Conflicting own state revisions')
    chosen=max((a,b),key=lambda item:item['generation'])
    catalog=json.loads(payloads[base+'catalog.json'])
    report,_=importer.validate(chosen['state'],catalog)
    report['generation']=chosen['generation']
    report['pendingOperations']=sum(op.get('phase')not in('done','cancelled')for op in chosen['state']['operations'].values())
    return report

def captured_state(root,previous,work,mounts,continuing):
    states,importer=modules();payloads={};sources={}
    base='resources/[scriptcore]/ic_mansions/'
    for relative,kind in states.FILES.items():
        if relative.startswith(base)and not continuing:continue
        selected=source_file(root,previous,relative,mounts)
        payloads[relative]=states.read_json(selected,kind)[0];sources[relative]=str(selected)
    if not continuing:
        legacy=work/'captured-mansions';legacy.mkdir(mode=0o700)
        for name in ('mansions.json','furniture_catalog.json'):
            selected=source_file(root,previous,'resources/[scriptcore]/m_mansions/'+name,mounts)
            raw=states.read_json(selected,dict)[0]
            target=legacy/name;target.write_bytes(raw);target.chmod(0o600)
        output=work/'imported-mansions'
        importer.prepare(legacy,output,apply=True,writers_stopped=True);importer.verify(output)
        for name in ('state-a.json','state-b.json','catalog.json'):
            payloads[base+name]=(output/name).read_bytes();sources[base+name]=str(output/name)
    report=own_state(payloads,importer)
    snapshot=work/'snapshot';snapshot.mkdir(mode=0o700)
    for relative,raw in payloads.items():
        file=snapshot/relative;file.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
        file.write_bytes(raw);file.chmod(0o600)
    write(snapshot/'manifest.json',{'version':1,'files':{p:hashlib.sha256(raw).hexdigest()for p,raw in payloads.items()}})
    return payloads,sources,report

def install_state(root,payloads):
    states,_=modules();installed=[]
    for relative,raw in payloads.items():
        destination=persistent_path(root,relative);states.safe_path(destination)
        if destination.exists():
            if destination.read_bytes()!=raw:raise CutoverError('Existing persistent state differs; reconcile instead of overwriting')
        else:
            destination.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
            with destination.open('xb')as stream:os.chmod(destination,0o600);stream.write(raw)
            installed.append(relative)
        if os.geteuid()==0:os.chown(destination,1000,1000)
        destination.chmod(0o600)
    return installed

def overlay_text(root,release,payloads):
    lines=['# Generated for this release; sources are shared persistent files.', 'services:', '  fxserver:', '    volumes:']
    targets=[]
    for relative in payloads:
        # Older releases may not contain the independent resources. Never create
        # target placeholders inside an immutable previous release during rollback.
        if not(release/relative).is_file():continue
        destination=persistent_path(root,relative);targets.append(relative)
        lines+=['      - type: bind','        source: '+json.dumps(str(destination)),
                '        target: '+json.dumps('/server-data/'+relative),'        read_only: false',
                '        bind:','          create_host_path: false']
    lines+=['  backup:','    volumes:','      - type: bind',
            '        source: '+json.dumps(str(root/'state/ic-config')),
            '        target: /ic-config-control','        read_only: true','        bind:','          create_host_path: false']
    return '\n'.join(lines)+'\n',targets

def backup_file(root):
    files=sorted((root/'backups').glob('vrp-*.sql.gz'),key=lambda p:p.stat().st_mtime)
    if not files or time.time()-files[-1].stat().st_mtime>1800:raise CutoverError('A fresh stopped-writer database backup is required')
    path=files[-1];expected=path.with_name(path.name+'.sha256').read_text().split()[0]
    if hashlib.sha256(path.read_bytes()).hexdigest()!=expected:raise CutoverError('Database backup checksum differs')
    return path

def migration_context(root,release):
    migration=load('ic-config-migrate.py','config_migration')
    args=types.SimpleNamespace(env_file=str(root/'.env'),project_name='interior-city-tocado',
        project_directory=str(root),compose_file=[str(release/'compose.yaml')])
    return migration,migration.Database(args)

def rehearse_schema(root,work,backup,live,migration):
    helper=load('ic-admin-cutover.py','backup_rehearsal')
    source_counts=helper.counts(live)
    class RepeatedSchema:
        @staticmethod
        def apply_schema(db):migration.apply_schema(db);migration.apply_schema(db);return migration.verify_schema(db)
    return helper.rehearse(root,work,backup,source_counts,RepeatedSchema,None)

def prepare(root,previous,release):
    _,mounts=stopped_writers();validate_candidate(release)
    control=safe(root/'state/ic-config');control.mkdir(mode=0o700,exist_ok=True)
    selection=control/'selection.json'
    prior=json.loads(selection.read_text())if selection.exists()else None
    previous_selected=(previous/'config/ic_config_runtime.cfg').is_file()
    if prior and not previous_selected:raise CutoverError('Prior own-service state exists; legacy rollback requires explicit reconciliation')
    if previous_selected and not prior:raise CutoverError('Own previous release needs its operational selection report')
    continuing=bool(prior)
    work=safe(control/('prepare-'+release.name))
    if work.exists():raise CutoverError('Preparation workspace exists; inspect it before retrying this release')
    work.mkdir(mode=0o700)
    backup=backup_file(root)
    payloads,sources,counts=captured_state(root,previous,work,mounts,continuing)
    migration,live=migration_context(root,release)
    rehearsal=rehearse_schema(root,work,backup,live,migration)
    schema=migration.apply_schema(live)
    stopped_writers()
    created=install_state(root,payloads)
    overlays=safe(control/'overlays');overlays.mkdir(mode=0o700,exist_ok=True)
    for target in (previous,release):
        content,targets=overlay_text(root,target,payloads)
        path=overlays/(target.name+'.yaml')
        if path.is_symlink():raise CutoverError('Overlay cannot be a symlink')
        path.write_text(content);path.chmod(0o600)
    report={'version':1,'release':release.name,'previous':previous.name,'phase':'prepared',
        'continuing':continuing,'legacyReimported':not continuing,'stateFiles':len(payloads),
        'createdFiles':created,'sources':sources,'counts':counts,'schema':schema,
        'backup':backup.name,'backupSha256':hashlib.sha256(backup.read_bytes()).hexdigest(),
        'restorationRehearsal':rehearsal,'runtimeVerified':False,'gameClientsValidated':False}
    write(control/(release.name+'.json'),report)
    return {'prepared':True,'continuing':continuing,'stateFiles':len(payloads),'counts':counts,'schemaVersion':1}

def mark_starting(root,release):
    control=root/'state/ic-config';path=control/(release.name+'.json')
    report=json.loads(path.read_text())
    if report['phase']!='prepared':raise CutoverError('Candidate was not prepared')
    report['phase']='starting';write(path,report)
    write(control/'selection.json',{'version':1,'release':release.name,'phase':'starting','provider':'ic_mansions'})

def markers(container):
    result=subprocess.run(['docker','logs','--tail','4000',container],capture_output=True,text=True)
    found={}
    for line in (result.stdout+'\n'+result.stderr).splitlines():
        line=re.sub(r'\x1b\[[0-9;]*m','',line)
        match=re.search(r'\[(ic_config|ic_mansions):operational\]\s*(\{.*\})',line)
        if match:
            try:found[match[1]]=json.loads(match[2])
            except ValueError:continue
    return found

def verify_runtime(root,release):
    control=root/'state/ic-config';path=control/(release.name+'.json');report=json.loads(path.read_text())
    deadline=time.monotonic()+150
    while time.monotonic()<deadline:
        try:
            container,info=container_info();observed=markers(container);endpoint=None
            if info['State']['Running']is not True:raise CutoverError('Candidate FXServer is not running')
            for network in info.get('NetworkSettings',{}).get('Networks',{}).values():
                address=network.get('IPAddress')
                if not address:continue
                with urllib.request.urlopen('http://'+address+':30120/info.json',timeout=3)as response:endpoint=json.load(response)
                break
            resources=(endpoint or{}).get('resources',[])
            if set(('ic_config','ic_mansions'))<=set(resources)and not set(('mg_config_panel','m_mansions'))&set(resources):
                if observed.get('ic_config',{}).get('active')is True and observed.get('ic_config',{}).get('provider')=='ic_config' and observed.get('ic_config',{}).get('schemaVersion')==1 and observed.get('ic_mansions',{}).get('active')is True and observed.get('ic_mansions',{}).get('provider')=='ic_mansions':break
        except (OSError,ValueError,CutoverError):pass
        time.sleep(2)
    else:raise CutoverError('Own services did not become operational; candidate must stay stopped for inspection')
    migration,live=migration_context(root,release);migration.verify_schema(live)
    expected=load('ic-config-state.py','runtime_state').FILES
    mounts={m.get('Destination'):m for m in info.get('Mounts',[])}
    for relative in expected:
        mount=mounts.get('/server-data/'+relative)
        if not mount or mount.get('Source')!=str(persistent_path(root,relative))or mount.get('RW')is not True:
            raise CutoverError('Runtime persistence mount differs from the prepared state')
    report.update(phase='active',runtimeVerified=True,runtime=observed)
    write(path,report);write(control/'selection.json',{'version':1,'release':release.name,'phase':'active','provider':'ic_mansions'})
    return {'runtimeVerified':True,'legacyStopped':True,'stateFiles':len(expected)}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode',choices=('configure-candidate','check-previous','prepare','mark-starting','verify-runtime'))
    p.add_argument('--root',type=Path,required=True);p.add_argument('--previous',type=Path);p.add_argument('--release',type=Path)
    p.add_argument('--allow-ic-admin-state',action='store_true')
    args=p.parse_args()
    if os.geteuid()!=0:raise CutoverError('Root authentication required')
    root=safe(args.root)
    for path in (args.previous,args.release):
        if path:
            safe(path)
            if path.parent!=root/'releases'or not re.fullmatch(r'[a-f0-9]{40}|\.incoming-[a-f0-9]{40}\.[A-Za-z0-9]+',path.name):
                raise CutoverError('Invalid managed release path')
    if args.mode=='configure-candidate':
        if not args.release.name.startswith('.incoming-'):raise CutoverError('Render only an unsealed incoming candidate')
        result=configure_candidate(args.release)
    elif args.mode=='check-previous':result=check_previous(root,args.previous,args.allow_ic_admin_state)
    elif args.mode=='prepare':result=prepare(root,args.previous,args.release)
    elif args.mode=='mark-starting':mark_starting(root,args.release);result={'starting':True,'automaticRollbackDisabled':True}
    else:result=verify_runtime(root,args.release)
    print(json.dumps(result,sort_keys=True))

if __name__=='__main__':
    try:main()
    except Exception as error:
        print(str(error)if isinstance(error,CutoverError)else'Cutover failed; private values and diagnostics suppressed',file=sys.stderr)
        raise SystemExit(1)
