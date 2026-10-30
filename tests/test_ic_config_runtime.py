"""Run the real IC Config Lua resource with simulated host/export boundaries."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ICConfigRuntimeTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_operational_marker_requires_schema_and_single_provider(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/ic_config_health.lua'), str(ROOT)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_garage_owner_persistence_failures(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/ic_config_garage.lua'), str(ROOT)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_server_security_and_adapters(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/ic_config_server.lua'), str(ROOT)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('luac'), 'Lua compiler unavailable')
    def test_lua_syntax(self):
        for path in (ROOT / 'resources/[scriptcore]/ic_config').rglob('*.lua'):
            with self.subTest(path=path.name):
                result = subprocess.run(['luac', '-p', str(path)], text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
