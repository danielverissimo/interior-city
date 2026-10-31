"""Validate food registration across the real Lua catalogs and generated media."""
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'media/foods'


class InventoryFoodsTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_consumption_and_catalog_contracts(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/inventory_foods.lua'), str(ROOT)],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_generated_images_match_manifest_and_inventory_names(self):
        catalog = json.loads((MEDIA / 'catalog.json').read_text())
        manifest = json.loads((MEDIA / 'images.manifest.json').read_text())
        expected = {entry['image'] for entry in catalog['items']}
        self.assertEqual(expected, set(manifest['files']))
        self.assertEqual(expected, {p.relative_to(MEDIA).as_posix() for p in (MEDIA / 'images').glob('*.png')})
        for relative, record in manifest['files'].items():
            with self.subTest(image=relative):
                data = (MEDIA / relative).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), record['sha256'])
                self.assertEqual(len(data), record['size'])
                self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
                width, height, depth, color = struct.unpack('>IIBB', data[16:26])
                self.assertEqual((width, height, depth, color), (512, 512, 8, 6))


if __name__ == '__main__':
    unittest.main()
