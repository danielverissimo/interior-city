"""Exercise real Lua/JS modules with simulated FiveM/DB boundaries."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]

class ICAdminRuntimeTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_lua_behavior_harnesses(self):
        for name in ('ic_admin_core.lua','ic_admin_services.lua','ic_admin_monitor.lua','ic_admin_maintenance.lua','ic_admin_discipline.lua','ic_admin_inventory.lua'):
            with self.subTest(harness=name):
                result=subprocess.run(['lua',str(ROOT/'tests'/name),str(ROOT)],text=True,capture_output=True)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    @unittest.skipUnless(shutil.which('node'), 'Node unavailable')
    def test_web_transport_contracts(self):
        result=subprocess.run(['node','--test',str(ROOT/'tests/ic_admin_web.test.mjs')],text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    @unittest.skipUnless(shutil.which('luac'), 'Lua compiler unavailable')
    def test_resource_lua_syntax(self):
        for path in (ROOT/'resources/[scriptcore]/ic_admin').rglob('*.lua'):
            with self.subTest(path=path.name):
                result=subprocess.run(['luac','-p',str(path)],text=True,capture_output=True)
                self.assertEqual(result.returncode,0,result.stderr)
