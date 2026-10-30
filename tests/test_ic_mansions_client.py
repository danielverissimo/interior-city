from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MansionClientTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua unavailable')
    def test_client_lifecycle_placement_and_cleanup(self):
        result = subprocess.run(
            ['lua', str(ROOT / 'tests/ic_mansions_client.lua'), str(ROOT)],
            capture_output=True, text=True, timeout=20,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
