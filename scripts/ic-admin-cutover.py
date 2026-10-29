#!/usr/bin/env python3
"""Explicit, root-only Uriel cutover; credentials and player records never enter reports."""
import argparse,gzip,hashlib,json,os,re,secrets,shutil,subprocess,sys,tempfile,time,types,urllib.request
from pathlib import Path
sys.dont_write_bytecode=True

class CutoverError(ValueError):pass
def load(path,name):
    module=types.ModuleType(name);module.__file__=str(path)
    exec(compile(path.read_text(),str(path),'exec'),module.__dict__);return module
def run(args,input=None,timeout=180):
    result=subprocess.run(args,input=input,text=True,capture_output=True,timeout=timeout)
    if result.returncode:raise CutoverError('Operational command failed; private diagnostics suppressed')
    return result.stdout.rstrip('\r\n')
def write(path,data):
    path=Path(path);temporary=path.with_suffix('.next')
    temporary.write_text(json.dumps(data,ensure_ascii=False,sort_keys=True,indent=2)+'\n');temporary.chmod(0o600);temporary.replace(path)
def containers():
    return dict(line.split('\t',1)[::-1] for line in run(['docker','ps','-a','--filter','label=com.docker.compose.project=interior-city-tocado','--format','{{.ID}}\t{{.Label "com.docker.compose.service"}}']).splitlines())
def stopped_writers():
    container=containers().get('fxserver')
    if not container or run(['docker','inspect','--format','{{.State.Running}}',container])!='false':raise CutoverError('Legacy writers must be stopped')
    return container
def deduplicate_locked_assets(current,older,lock):
    assets=load(Path(__file__).with_name('assets.py'),'asset_reuse') if Path(__file__).with_name('assets.py').exists() else load(current/'scripts/assets.py','asset_reuse')
    reused=0;size=0
    for package in lock['packages']:
        for record in package['files']:
            source=assets.target_path(current,record['path']);target=assets.target_path(older,record['path'])
            if not source.is_file() or not target.is_file():continue
            a,b=source.stat(),target.stat()
            if a.st_dev!=b.st_dev or a.st_ino==b.st_ino or a.st_size!=record['size'] or b.st_size!=record['size']:continue
            if assets.file_hash(source)!=record['sha256'] or assets.file_hash(target)!=record['sha256']:continue
            temporary=target.with_name('.ic-admin-dedup-'+secrets.token_hex(6))
            try:os.link(source,temporary);os.replace(temporary,target)
            finally:temporary.unlink(missing_ok=True)
            reused+=1;size+=b.st_size
    return reused,size
def ensure_capacity(root,current):
    minimum=3*1024**3
    if shutil.disk_usage(root).free>=minimum:return
    lock_path=current/'assets.lock.json'
    if not lock_path.is_file():raise CutoverError('Insufficient disk space and no immutable catalogue for safe reuse')
    lock=json.loads(lock_path.read_text());digest=hashlib.sha256(lock_path.read_bytes()).hexdigest()
    running=run(['docker','ps','-q']).splitlines();mounted=[]
    if running:
        for container in json.loads(run(['docker','inspect',*running])):
            mounted.extend(Path(mount['Source']).resolve() for mount in container.get('Mounts',[]) if mount.get('Source'))
    reused=0;logical=0;cleared=0
    for older in sorted((root/'releases').iterdir()):
        if not re.fullmatch('[a-f0-9]{40}',older.name) or older.is_symlink() or older.resolve()==current.resolve():continue
        if any(path==older or older in path.parents for path in mounted):continue
        old_lock=older/'assets.lock.json'
        if not old_lock.is_file() or hashlib.sha256(old_lock.read_bytes()).hexdigest()!=digest:continue
        count,size=deduplicate_locked_assets(current,older,lock);reused+=count;logical+=size
        cache=older/'cache'
        if count and cache.is_dir() and not cache.is_symlink():shutil.rmtree(cache);cleared+=1
        if shutil.disk_usage(root).free>=minimum:break
    free=shutil.disk_usage(root).free
    print(json.dumps({'migrationStorageReuse':{'immutableFiles':reused,'logicalDuplicateBytes':logical,'inactiveCachesRebuiltLater':cleared,'freeBytes':free}}),flush=True)
    if free<minimum:raise CutoverError('Insufficient disk space after verified immutable reuse; no player data or backups removed')
def check_previous(root,previous):
    helper=load(Path(__file__).with_name('release.py'),'release_helper')
    previous=previous.resolve();expected=json.loads((root/'state/manifests'/(previous.name+'.json')).read_text())
    actual=helper.inventory(previous)
    migration=load(Path(__file__).with_name('ic-admin-migrate.py'),'migration_check') if Path(__file__).with_name('ic-admin-migrate.py').exists() else None
    files=migration.FILES if migration else ('panel_permissions.json','vip_packages.json','vip_assignments.json','locations.json','location_categories.json','calls_data.json','ban_history.json','warnings_data.json','environment_state.json','vehicles.json')
    allowed={'resources/[scriptcore]/m_paineladm_v2/'+name for name in (*files,'logs_config.json')}
    # Config Manager writes this JSON; the installer preserves it in shared state.
    mutable='resources/[scripts]/m_desmanche/config.json'
    config=previous/mutable
    if config.is_file() and config.stat().st_size<=32*1024*1024:
        try:document=json.loads(config.read_text())
        except (ValueError,UnicodeError):raise CutoverError('Invalid mutable dismantling configuration') from None
        if not isinstance(document,dict) or not isinstance(document.get('settings'),dict) or not isinstance(document.get('desmanches'),list):raise CutoverError('Unknown mutable dismantling configuration structure')
        allowed.add(mutable)
    drift=[key for key in sorted(set(actual)|set(expected)) if actual.get(key)!=expected.get(key)]
    # The read-only preflight imported the verified helper; its generated bytecode is disposable.
    caches={key for key in drift if re.fullmatch(r'scripts/__pycache__/release\.cpython-\d+\.pyc',key) and key not in expected}
    if set(drift)-allowed-caches:raise CutoverError('Release validation failed: immutable code/configuration drift requires review')
    print(json.dumps({'previousRelease':previous.name,'reviewedMutableFiles':[p for p in drift if p in allowed],'generatedCacheFiles':len(caches)}))
    ensure_capacity(root,previous)
    return drift
class EphemeralDB:
    def __init__(self,name):self.name=name
    def query(self,sql):
        return run(['docker','exec','-i',self.name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --batch --raw --skip-column-names --binary-mode --default-character-set=utf8mb4 vrp'],sql,timeout=300)
def counts(db):
    tables=db.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='vrp' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;").splitlines()
    if any(not re.fullmatch('[A-Za-z0-9_]+',name) for name in tables):raise CutoverError('Unexpected table identifier')
    sql=''.join("SELECT '"+name+"',COUNT(*) FROM `"+name+'`;' for name in tables)
    return {line.split('\t')[0]:int(line.split('\t')[1]) for line in db.query(sql).splitlines()}
def rehearse(root,work,backup,source_counts,migration,imported):
    name='ic-admin-restore-'+secrets.token_hex(5)
    env=work/'restore.env';env.write_text('MARIADB_ROOT_PASSWORD='+secrets.token_hex(32)+'\nMARIADB_DATABASE=vrp\n');env.chmod(0o600)
    try:
        run(['docker','run','-d','--rm','--pull','never','--network','none','--name',name,'--env-file',str(env),'mariadb:10.11.19'])
        db=EphemeralDB(name)
        for _ in range(120):
            try:db.query('SELECT 1;');break
            except CutoverError:time.sleep(.5)
        else:raise CutoverError('Backup rehearsal database readiness failed')
        with gzip.open(backup,'rt') as stream:
            process=subprocess.Popen(['docker','exec','-i',name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --binary-mode --default-character-set=utf8mb4'],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,text=True)
            try:
                while block:=stream.read(1024*1024):process.stdin.write(block)
                process.stdin.close()
                if process.wait(timeout=300):raise CutoverError('Backup restoration failed; current database was not replaced')
            finally:
                if process.poll() is None:process.kill();process.wait()
        if counts(db)!=source_counts:raise CutoverError('Restored backup table counts differ from the stopped database')
        migration.apply_schema(db)
        if imported is not None:
            first=migration.apply_import(db,imported,replace_imported=True)
            second=migration.apply_import(db,imported,verify=True)
            migration.apply_import(db,imported)
        else:first=second={'verified':True}
        if not first.get('verified') or not second.get('verified'):raise CutoverError('Isolated migration verification failed')
        return {'restored':True,'tableCountsMatch':True,'tables':len(source_counts),'migrationRepeated':True}
    finally:
        subprocess.run(['docker','rm','-f',name],capture_output=True);env.unlink(missing_ok=True)

def recover_legacy_kvp(root,previous,work):
    """Read only the old resource namespace on a copied RocksDB using the same FXServer."""
    stopped_writers()
    probe=work/'kvp-probe';resource=probe/'resources/m_paineladm_v2';resource.mkdir(parents=True)
    if any(path.is_symlink() for path in (root/'state/kvp').rglob('*')):raise CutoverError('KVP snapshot must not contain symlinks')
    shutil.copytree(root/'state/kvp',probe/'db')
    (resource/'fxmanifest.lua').write_text("fx_version 'cerulean'\ngame 'gta5'\nserver_script 'read.lua'\n")
    (resource/'read.lua').write_text('''CreateThread(function()
    local values={};local handle=StartFindKvp('');local count=0;local unsupported=0;local credentials=0
    if handle and handle~=-1 then
        while true do local key=FindKvp(handle);if not key then break end;count=count+1
            local lower=key:lower()
            if lower:find('token',1,true) or lower:find('secret',1,true) or lower:find('license',1,true) or lower:find('auth',1,true) then
                credentials=credentials+1
            elseif lower:find('weather',1,true) or lower:find('climate',1,true) or lower:find('environment',1,true) or lower:find('clima',1,true) or lower:find('time',1,true) or lower:find('hora',1,true) or lower:find('rotation',1,true) or lower:find('permission',1,true) or lower:find('logs_config',1,true) then
                local ok,value=pcall(GetResourceKvpString,key)
                if not ok then ok,value=pcall(GetResourceKvpFloat,key) end
                if not ok then ok,value=pcall(GetResourceKvpInt,key) end
                if ok and value~=nil then values[key]=value else unsupported=unsupported+1 end
            else unsupported=unsupported+1 end
        end
        EndFindKvp(handle)
    end
    SaveResourceFile(GetCurrentResourceName(),'result.json',json.encode({keyCount=count,values=values,unsupported=unsupported,credentialsSkipped=credentials}),-1)
    print('[ic_admin_import] KVP namespace inspected without running the legacy core.')
end)
''')
    (probe/'probe.cfg').write_text('exec runtime/secret.cfg\nendpoint_add_tcp "127.0.0.1:31371"\nendpoint_add_udp "127.0.0.1:31371"\nsv_lan true\nsv_maxclients 1\nensure m_paineladm_v2\n')
    for path in [probe,*probe.rglob('*')]:os.chown(path,1000,1000)
    old=containers()['fxserver'];inspect=json.loads(run(['docker','inspect',old]))[0]
    networks=inspect['NetworkSettings']['Networks'];network=next((n for n in networks if n.endswith('_egress')),None)
    if not network:raise CutoverError('KVP recovery egress network unavailable')
    name='ic-admin-kvp-'+secrets.token_hex(5)
    try:
        run(['docker','run','-d','--rm','--pull','never','--name',name,'--network',network,'--user','1000:1000',
            '--workdir','/probe','--mount','type=bind,src='+str(probe)+',dst=/probe',
            '--mount','type=bind,src='+str(root/'secrets/cfx_license')+',dst=/run/secrets/cfx_license,readonly',
            '--tmpfs','/probe/runtime:uid=1000,gid=1000,mode=0700','--entrypoint','/bin/bash','interior-city/fxserver-tocado:35245','-c',
            'umask 077; printf \'sv_licenseKey "%s"\\n\' "$(cat /run/secrets/cfx_license)" > runtime/secret.cfg; exec /opt/fxserver/run.sh +exec probe.cfg'])
        for _ in range(90):
            if (resource/'result.json').is_file():break
            time.sleep(1)
        else:raise CutoverError('KVP recovery did not complete; legacy state was preserved')
        value=json.loads((resource/'result.json').read_text())
        return value
    finally:subprocess.run(['docker','rm','-f',name],capture_output=True)

def normalize_environment(value):
    if value.get('unsupported'):raise CutoverError('Persisted climate KVP type needs an explicit converter')
    candidates=[];scalars={}
    aliases={'weather':'weather','currentweather':'weather','hour':'hour','currenthour':'hour','minute':'minute','currentminute':'minute',
        'freezeweather':'freezeWeather','weatherfrozen':'freezeWeather','freezetime':'freezeTime','timefrozen':'freezeTime','rotation':'rotation'}
    for key,raw in value['values'].items():
        try:item=json.loads(raw) if isinstance(raw,str) else raw
        except ValueError:item=raw
        if isinstance(item,dict) and any(k in item for k in ('weather','currentWeather')) and any(k in item for k in ('hour','currentHour')):candidates.append(item)
        normalized=re.sub('[^a-z]','',key.lower())
        if normalized in aliases:
            field=aliases[normalized]
            if field in ('freezeWeather','freezeTime','rotation') and item in (0,1):item=bool(item)
            if field in scalars and scalars[field]!=item:raise CutoverError('Conflicting scalar climate KVP states require reconciliation')
            scalars[field]=item
    if 'weather' in scalars and 'hour' in scalars:candidates.append(scalars)
    if value['values'] and not candidates:raise CutoverError('Persisted climate KVP format needs an explicit converter')
    if len({json.dumps(item,sort_keys=True) for item in candidates})>1:raise CutoverError('Conflicting climate KVP states require reconciliation')
    return candidates[0] if candidates else None

def merge_legacy_kvp(value,captured):
    """Reconcile operational KVP with JSON before sealing; private destinations stay private."""
    if value.get('unsupported'):raise CutoverError('Unknown legacy KVP records require an explicit converter')
    climate={};settings={}
    for key,raw in value.get('values',{}).items():
        lower=key.lower()
        filename='panel_permissions.json' if 'permission' in lower else 'logs_config.json' if 'logs_config' in lower else None
        if not filename:
            climate[key]=raw;continue
        try:document=json.loads(raw) if isinstance(raw,str) else raw
        except ValueError:raise CutoverError('Invalid legacy KVP settings JSON') from None
        if not isinstance(document,dict):raise CutoverError('Unknown legacy KVP settings structure')
        if filename in settings and settings[filename]!=document:raise CutoverError('Conflicting legacy KVP settings require reconciliation')
        settings[filename]=document
    environment=normalize_environment({'values':climate})
    if environment is not None:settings['environment_state.json']=environment
    for name,document in settings.items():
        target=captured/name
        existing=json.loads(target.read_text()) if target.exists() and target.read_bytes().strip() else {}
        # Permissions have several documented equivalent wrappers.
        def comparable(item):
            if name=='panel_permissions.json' and isinstance(item,dict):
                return item.get('actions',item.get('functions',item.get('access',item)))
            return item
        if existing and comparable(existing)!=comparable(document):raise CutoverError('Legacy JSON and KVP disagree; explicit reconciliation required')
    for name,document in settings.items():write(captured/name,document)
    return {'namespaceKeys':value.get('keyCount',len(value.get('values',{}))),
        'environmentRecords':int(environment is not None),'permissionRecords':int('panel_permissions.json' in settings),
        'logRecords':int('logs_config.json' in settings),'credentialsSkipped':value.get('credentialsSkipped',0)}

def prepare(root,previous,release):
    stopped_writers()
    cfg=(release/'config/ic_admin.cfg').read_text();resources=(release/'config/resources.cfg').read_text()
    if 'setr ic_admin_mode "active"' not in cfg or 'setr ic_admin_service_resource "ic_admin"' not in cfg or re.search(r'^\s*(?:ensure|start)\s+m_paineladm_v2\s*$',resources,re.M):raise CutoverError('Candidate must select only IC Admin as active provider')
    migration=load(release/'scripts/ic-admin-migrate.py','migration')
    args=types.SimpleNamespace(env_file=str(root/'.env'),project_name='interior-city-tocado',project_directory=str(root),compose_file=[str(release/'compose.yaml')])
    live=migration.Database(args)
    source_counts=counts(live)
    marker=migration.read_documents(live,['migration:legacy']).get('migration:legacy')
    continuing=marker is not None and 'setr ic_admin_service_resource "ic_admin"' in (previous/'config/ic_admin.cfg').read_text()
    work=root/'state'/('ic-admin-migration-'+release.name)
    if work.exists():raise CutoverError('Migration workspace already exists; reconcile before retrying the same release')
    work.mkdir(mode=0o700)
    backups=sorted((root/'backups').glob('vrp-*.sql.gz'),key=lambda p:p.stat().st_mtime)
    if not backups or time.time()-backups[-1].stat().st_mtime>1800:raise CutoverError('A fresh stopped-writer backup is required')
    backup=backups[-1];checksum=backup.with_name(backup.name+'.sha256').read_text().split()[0]
    if hashlib.sha256(backup.read_bytes()).hexdigest()!=checksum:raise CutoverError('Predeploy backup checksum mismatch')
    if continuing:
        # Forward fixes after starting the new writer must never reimport old JSON.
        rehearsal=rehearse(root,work,backup,source_counts,migration,None)
        migration.apply_schema(live)
        previous_report=root/'state'/('ic-admin-cutover-'+previous.name+'.json')
        if not previous_report.is_file():raise CutoverError('Existing IC Admin migration needs its operational report before a forward fix')
        report=json.loads(previous_report.read_text())
        report.update(release=release.name,previous=previous.name,continuedFrom=previous.name,restorationRehearsal=rehearsal,runtimeVerified=False)
        write(root/'state'/('ic-admin-cutover-'+release.name+'.json'),report)
        print(json.dumps({'forwardFix':True,'legacyNotReimported':True,'schemaVersion':2}));return
    # Preserve all mutable legacy JSON, including private log settings, in a root-only archive.
    import tarfile
    source=previous/'resources/[scriptcore]/m_paineladm_v2'
    with tarfile.open(work/'legacy-original-json.tar.gz','w:gz') as archive:
        for file in source.glob('*.json'):
            if file.is_symlink():raise CutoverError('Legacy mutable JSON cannot be a symlink')
            archive.add(file,arcname=file.name,recursive=False)
    captured=work/'captured';captured.mkdir(mode=0o700)
    for name in migration.FILES:shutil.copyfile(source/name,captured/name)
    if (source/'logs_config.json').is_file():shutil.copyfile(source/'logs_config.json',captured/'logs_config.json')
    # The old panel can persist permissions and destinations in KVP even when JSON is empty.
    climate=merge_legacy_kvp(recover_legacy_kvp(root,previous,work),captured)
    snapshot=work/'snapshot'
    capture=migration.seal_snapshot(captured,snapshot,root/'state/resources/vrp/groups.json',True)
    imported=migration.build_import(snapshot)
    rehearsal=rehearse(root,work,backup,source_counts,migration,imported)
    stopped_writers()
    migration.apply_schema(live)
    applied=migration.apply_import(live,imported,replace_imported=True)
    verified=migration.apply_import(live,imported,verify=True)
    after=counts(live)
    # Legacy/player table row counts cannot change during an administrative import.
    if any(after.get(k)!=v for k,v in source_counts.items() if not k.startswith('ic_admin_')):raise CutoverError('Legacy/player table counts changed unexpectedly')
    report={'release':release.name,'previous':previous.name,'schemaVersion':2,'snapshot':capture,
        'restorationRehearsal':rehearsal,'imported':applied,'verified':verified,'climateRecovery':climate,
        'counts':{'vipPackages':len(imported['documents']['vip_packages']['packages']),'vipAssignments':len(imported['documents']['vip_assignments']['assignments']),
        'locations':len(imported['documents']['locations']['locations']),'categories':len(imported['documents']['locations']['categories']),
        'calls':len(imported['documents']['calls']['calls']),'ratings':len(imported['documents']['calls']['ratings']),'discipline':len(imported['discipline'])},
        'legacyRetainedForRollback':True,'gameClientsValidated':False,'runtimeVerified':False}
    write(root/'state'/('ic-admin-cutover-'+release.name+'.json'),report)
    print(json.dumps({'importVerified':True,'schemaVersion':2,'counts':report['counts'],'backupRehearsal':rehearsal}))

def operational_marker(container):
    # Container logs belong to this boot; a shared txAdmin log can contain stale readiness.
    result=subprocess.run(['docker','logs','--tail','4000',container],capture_output=True,text=True)
    marker=None
    for line in (result.stdout+'\n'+result.stderr).splitlines():
        line=re.sub(r'\x1b\[[0-9;]*m','',line)
        match=re.search(r'\[ic_admin:operational\]\s*(\{.*\})',line)
        if match:
            try:marker=json.loads(match[1])
            except ValueError:continue
    return marker

def verify_runtime(root,release):
    path=root/'state'/('ic-admin-cutover-'+release.name+'.json');report=json.loads(path.read_text())
    deadline=time.monotonic()+150;info=None;marker=None
    while time.monotonic()<deadline:
        fx=containers().get('fxserver')
        if fx:
            inspect=json.loads(run(['docker','inspect',fx]))[0]
            for net in inspect['NetworkSettings']['Networks'].values():
                if not net.get('IPAddress'):continue
                try:
                    with urllib.request.urlopen('http://'+net['IPAddress']+':30120/info.json',timeout=3) as response:info=json.load(response)
                    break
                except Exception:pass
            if info and 'ic_admin' in info.get('resources',[]):
                marker=operational_marker(fx)
                if marker and marker.get('active') is True and marker.get('schemaVersion')==2 and marker.get('provider')=='ic_admin':break
        time.sleep(2)
    if not info:raise CutoverError('Game endpoint did not become ready; inspect private runtime logs')
    resources=info.get('resources',[])
    if 'ic_admin' not in resources or 'mg_config_panel' not in resources or 'm_paineladm_v2' in resources:raise CutoverError('Runtime resource authority verification failed')
    if not marker or marker.get('active') is not True or marker.get('provider')!='ic_admin' or marker.get('schemaVersion')!=2:raise CutoverError('IC Admin database/authority readiness marker missing or inactive')
    report.update(runtimeVerified=True,runtime=marker,configManagerStarted=True,legacyStopped=True)
    write(path,report);print(json.dumps({'runtimeVerified':True,'legacyStopped':True,'runtime':marker}))

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('mode',choices=['check-previous','prepare','verify-runtime'])
    parser.add_argument('--root',type=Path,required=True);parser.add_argument('--previous',type=Path);parser.add_argument('--release',type=Path)
    args=parser.parse_args()
    if os.geteuid()!=0:raise CutoverError('Root authentication required')
    root=args.root.resolve()
    for path in (args.previous,args.release):
        if path and (path.resolve().parent!=root/'releases' or not re.fullmatch('[a-f0-9]{40}',path.name)):raise CutoverError('Invalid managed release path')
    if args.mode=='check-previous':check_previous(root,args.previous)
    elif args.mode=='prepare':prepare(root,args.previous,args.release)
    else:verify_runtime(root,args.release)
if __name__=='__main__':
    try:main()
    except (CutoverError,ValueError,OSError,subprocess.SubprocessError) as error:
        print(str(error) if isinstance(error,CutoverError) or type(error).__name__=='MigrationError' else 'Cutover failed; private input and diagnostics suppressed',file=sys.stderr);sys.exit(1)
