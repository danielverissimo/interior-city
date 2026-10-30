from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ConfigClientTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua unavailable')
    def test_lifecycle_and_local_captures(self):
        run = subprocess.run(['lua', str(ROOT / 'tests/ic_config_client.lua'), str(ROOT)],
                             capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    @unittest.skipUnless(shutil.which('lua'), 'Lua unavailable')
    def test_doors_capture_compatibility(self):
        run = subprocess.run(['lua', str(ROOT / 'tests/ic_config_doors.lua'), str(ROOT)],
                             capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)


if __name__ == '__main__':
    unittest.main()
