from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ICMansionsRuntimeTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua unavailable')
    def test_server_lifecycle_economy_and_integrations(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/ic_mansions_server.lua'), str(ROOT)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('luac'), 'Lua compiler unavailable')
    def test_server_lua_syntax(self):
        for path in (ROOT / 'resources/[scriptcore]/ic_mansions/server').glob('*.lua'):
            result = subprocess.run(['luac', '-p', str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, str(path) + result.stderr)


if __name__ == '__main__':
    unittest.main()
