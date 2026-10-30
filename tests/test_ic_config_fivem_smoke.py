"""Opt-in native FXServer boot, with own resources and synthetic dependency APIs.

No vendor resource, credential, host port, external network or live state is used.
This checks engine initialization, storage natives and the Lua export ABI only;
it is not gameplay validation with GTA clients.
"""
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
import time
import unittest

ROOT=Path(__file__).resolve().parents[1]
IMAGE=os.environ.get('IC_CONFIG_FXSERVER_IMAGE')

@unittest.skipUnless(IMAGE,'Opt-in native FXServer image required')
class NativeBootTests(unittest.TestCase):
    def test_own_resources_boot_and_use_native_files_and_export_proxy(self):
        with tempfile.TemporaryDirectory(prefix='ic-config-native-')as tmp:
            work=Path(tmp).resolve();resources=work/'resources';resources.mkdir()
            for name in ('ic_config','ic_mansions'):
                shutil.copytree(ROOT/'resources/[scriptcore]'/name,resources/name)
            def resource(name,files):
                directory=resources/name;directory.mkdir()
                for filename,body in files.items():
                    target=directory/filename;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(body)
                return directory
            manifest="fx_version 'cerulean'\ngame 'gta5'\nlua54 'yes'\nserver_script 'server.lua'\n"
            resource('vrp',{'fxmanifest.lua':manifest,'server.lua':'',
                'lib/utils.lua':"function module(resource,path) local source=assert(LoadResourceFile(resource,path..'.lua'));return assert(load(source,'@'..resource..'/'..path))()end\n",
                'lib/Proxy.lua':"return {getInterface=function()return {getUserId=function()return nil end,getUserGroups=function()return{}end}end}"})
            metadata={'ic_config_schema':['version'],'ic_config_org_deletions':['org_name','operation_id','phase','actor_id','payload','updated_at'],
                'ic_config_deleted_groups':['group_name','operation_id'],'vrp_user_data':['user_id','dkey','dvalue'],
                'mirtin_orgs_goals':['organization'],'mirtin_orgs_player_infos':['organization'],
                'mirtin_orgs_chat':['organization'],'sjr_logs':['organization'],
                'mirtin_organization_members':['group_type'],'mirtin_orgs_info':['organization']}
            tables=[{'TABLE_NAME':name,'ENGINE':'InnoDB'}for name in metadata]
            columns=[{'TABLE_NAME':name,'COLUMN_NAME':column}for name,fields in metadata.items()for column in fields]
            triggers=[{'TRIGGER_NAME':'ic_config_userdata_'+suffix}for suffix in('insert','update')]
            triggers += [{'TRIGGER_NAME':f'ic_config_org_{index}_{suffix}'}for index in range(1,7)for suffix in('insert','update')]
            mysql=('local tables=json.decode('+json.dumps(json.dumps(tables))+')\nlocal columns=json.decode('+json.dumps(json.dumps(columns))+')\n'
                'local triggers=json.decode('+json.dumps(json.dumps(triggers))+')\n'
                "MySQL={query={await=function(sql)if sql:find('MAX(version)',1,true)then return{{version=1}}elseif sql:find('information_schema.TABLES',1,true)then return tables elseif sql:find('information_schema.COLUMNS',1,true)then return columns elseif sql:find('information_schema.TRIGGERS',1,true)then return triggers end return{}end},transaction={await=function()return true end}}\n")
            resource('oxmysql',{'fxmanifest.lua':manifest,'server.lua':'','lib/MySQL.lua':mysql})
            for name in('inventory','m_garage','doorsv2'):resource(name,{'fxmanifest.lua':manifest,'server.lua':"exports('nativeEcho',function(value)return value end)\n"})
            resource('native_check',{'fxmanifest.lua':manifest,'server.lua':"""CreateThread(function()
  Wait(500)
  local raw='{"nativeStorage":true}'
  SaveResourceFile(GetCurrentResourceName(),'native.json',raw,#raw)
  assert(LoadResourceFile(GetCurrentResourceName(),'native.json')==raw,'native persistence failed')
  assert(exports['inventory']['nativeEcho'](nil,'owned-fixture')=='owned-fixture','Lua export ABI differs')
  print('[ic_config:native-smoke] '..json.encode({nativeStorage=true,exportsProxy=true}))
end)
"""})
            (work/'server.cfg').write_text('sv_lan true\nsv_maxclients 1\nsv_hostname "Local isolated IC Config validation"\n'
                'endpoint_add_tcp "127.0.0.1:31371"\nendpoint_add_udp "127.0.0.1:31371"\n'
                'set onesync on\nsetr ic_mansions_resource "ic_mansions"\nset ic_mansions_enabled "true"\n'
                'set ic_config_enabled "true"\nset ic_config_writes_enabled "false"\n'
                'ensure vrp\nensure oxmysql\nensure inventory\nensure m_garage\nensure doorsv2\nensure ic_mansions\nensure ic_config\nensure native_check\n')
            name='ic-config-native-'+secrets.token_hex(5)
            try:
                command=['docker','run','-d','--platform','linux/amd64','--network','none','--cap-drop','ALL',
                    '--security-opt','no-new-privileges','--name',name,'--user',str(os.getuid())+':'+str(os.getgid()),
                    '--mount','type=bind,source='+str(work)+',target=/server-data',
                    '--entrypoint','/opt/fxserver/run.sh',IMAGE,'+exec','server.cfg']
                started=subprocess.run(command,capture_output=True,text=True)
                self.assertEqual(started.returncode,0,'Native fixture container did not start')
                output=''
                for _ in range(90):
                    logs=subprocess.run(['docker','logs',name],capture_output=True,text=True);output=logs.stdout+'\n'+logs.stderr
                    if all(marker in output for marker in('[ic_config:native-smoke]','[ic_config:operational]','[ic_mansions:operational]')):break
                    state=subprocess.run(['docker','inspect','--format','{{.State.Running}}',name],capture_output=True,text=True)
                    if state.returncode or state.stdout.strip()!='true':break
                    time.sleep(1)
                if 'license key'in output.lower()or'licensekey'in output.lower():
                    self.skipTest('Offline FXServer requires a legitimate server license; no credential or authentication bypass used')
                if os.environ.get('IC_CONFIG_NATIVE_LOG'):
                    path=Path(os.environ['IC_CONFIG_NATIVE_LOG']);path.write_text(output);path.chmod(0o600)
                self.assertIn('[ic_config:native-smoke]',output,'Native resource check did not run; private diagnostics omitted')
                for marker in('[ic_config:operational]','[ic_mansions:operational]'):
                    rows=[line.split(marker,1)[1].strip()for line in output.splitlines()if marker in line]
                    self.assertTrue(rows and json.loads(rows[-1]).get('active')is True,marker+' not ready')
            finally:subprocess.run(['docker','rm','-f',name],capture_output=True)
