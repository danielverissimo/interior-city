#!/usr/bin/env python3
"""Explicit additive organization-deletion schema; never selects a live database."""
import argparse
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
SCHEMA=ROOT/'database/ic_config/001_organizations.sql'
SPEC=importlib.util.spec_from_file_location('ic_config_database',ROOT/'scripts/ic-admin-migrate.py')
database=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(database)
MigrationError=database.MigrationError
Database=database.Database
REQUIRED={
    'ic_config_schema':{'version'},
    'ic_config_org_deletions':{'org_name','operation_id','phase','actor_id','payload','updated_at'},
    'ic_config_deleted_groups':{'group_name','operation_id'},
    'vrp_user_data':{'user_id','dkey','dvalue'},
    'mirtin_orgs_goals':{'organization'},
    'mirtin_orgs_player_infos':{'organization'},
    'mirtin_orgs_chat':{'organization'},
    'sjr_logs':{'organization'},
    'mirtin_organization_members':{'group_type'},
    'mirtin_orgs_info':{'organization'}
}


def triggers():
    pattern=r'CREATE TRIGGER IF NOT EXISTS (\w+) (BEFORE|AFTER) (INSERT|UPDATE|DELETE) ON (\w+) FOR EACH ROW\s*(BEGIN.*?END)\$\$'
    return {name:(timing,event,table,body) for name,timing,event,table,body in re.findall(pattern,SCHEMA.read_text(),re.S)}


def normalize(sql):
    return re.sub(r'\s+',' ',sql.strip()).casefold()


def verify_tables(db,include_own=True,allow_missing_logs=False):
    required={table:columns for table,columns in REQUIRED.items() if include_own or not table.startswith('ic_config_')}
    names=','.join(database.sql_text(table) for table in sorted(required))
    rows=db.query('SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('+names+');')
    found={}
    for line in rows.splitlines():
        parts=line.split('\t')
        if len(parts)==2:found.setdefault(parts[0],set()).add(parts[1])
    for table,columns in required.items():
        if allow_missing_logs and table=='sjr_logs' and table not in found:continue
        if not columns<=found.get(table,set()):raise MigrationError('Required organization schema is missing or incompatible: '+table)
    engines={}
    for line in db.query('SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('+names+');').splitlines():
        parts=line.split('\t')
        if len(parts)==2:engines[parts[0]]=parts[1]
    for table in required:
        if allow_missing_logs and table=='sjr_logs' and table not in engines:continue
        if engines.get(table)!='InnoDB':raise MigrationError('Organization deletion requires InnoDB: '+table)


def verify_schema(db):
    verify_tables(db)
    if db.query('SELECT MAX(version) FROM ic_config_schema;')!='1':raise MigrationError('Unsupported IC Config schema version')
    expected=triggers()
    if len(expected)!=14:raise MigrationError('Unexpected migration trigger inventory')
    actual={}
    sql="SELECT TRIGGER_NAME,ACTION_TIMING,EVENT_MANIPULATION,EVENT_OBJECT_TABLE,HEX(ACTION_STATEMENT) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() AND TRIGGER_NAME LIKE 'ic_config_%';"
    for line in db.query(sql).splitlines():
        columns=line.split('\t')
        if len(columns)!=5:raise MigrationError('Invalid trigger metadata')
        try:body=bytes.fromhex(columns[4]).decode()
        except (ValueError,UnicodeError):raise MigrationError('Invalid trigger metadata') from None
        actual[columns[0]]=(*columns[1:4],body)
    if set(actual)!=set(expected):raise MigrationError('IC Config trigger inventory differs from the migration')
    for name,definition in expected.items():
        found=actual[name]
        if found[:3]!=definition[:3] or normalize(found[3])!=normalize(definition[3]):
            raise MigrationError('IC Config trigger definition differs from the migration: '+name)
    return {'schemaVersion':1,'tablesVerified':len(REQUIRED),'triggersVerified':len(expected)}


def apply_schema(db):
    verify_tables(db,include_own=False,allow_missing_logs=True)
    db.query(SCHEMA.read_text())
    return verify_schema(db)


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env-file')
    parser.add_argument('--project-name')
    parser.add_argument('--project-directory',default=str(ROOT))
    parser.add_argument('--compose-file',action='append')
    parser.add_argument('command',choices=('schema',))
    modes=parser.add_mutually_exclusive_group(required=True)
    for mode in ('dry-run','apply','verify'):modes.add_argument('--'+mode,action='store_true')
    parser.add_argument('--writers-stopped',action='store_true')
    args=parser.parse_args(argv)
    if args.dry_run:
        report={'schemaVersion':1,'ownTables':sorted(t for t in REQUIRED if t.startswith('ic_config_')),
                'requiredTables':sorted(t for t in REQUIRED if not t.startswith('ic_config_')),
                'triggers':sorted(triggers()),'databaseAccessed':False,'applied':False}
    elif args.apply:
        if not args.writers_stopped:raise MigrationError('Apply requires explicit --writers-stopped')
        report=apply_schema(Database(args))
    else:report=verify_schema(Database(args))
    print(json.dumps(report,sort_keys=True))
    return report


if __name__=='__main__':
    try:main()
    except (MigrationError,OSError,ValueError,subprocess.SubprocessError) as error:
        print(str(error) if isinstance(error,MigrationError) else 'Migration failed; input and database values suppressed',file=sys.stderr)
        raise SystemExit(1)
