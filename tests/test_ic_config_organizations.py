from pathlib import Path
import shutil
import subprocess
import unittest

ROOT=Path(__file__).resolve().parents[1]

class ICConfigOrganizationsTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'),'Lua unavailable')
    def test_preview_deletion_and_recovery(self):
        result=subprocess.run(['lua',str(ROOT/'tests/ic_config_organizations.lua'),str(ROOT)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    @unittest.skipUnless(shutil.which('lua'),'Lua unavailable')
    def test_actual_owning_resource_projections(self):
        result=subprocess.run(['lua',str(ROOT/'tests/ic_config_org_owners.lua'),str(ROOT)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
