import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('web_assets', ROOT / 'scripts/web-assets.py')
web = importlib.util.module_from_spec(spec)
spec.loader.exec_module(web)


class WebAssetsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'htdocs'
        for name in web.MEDIA:
            (self.source / name).mkdir(parents=True)
        (self.source / 'images/item.png').write_bytes(b'fixture-image')
        (self.source / 'vrp_images/car.png').write_bytes(b'fixture-car')
        (self.source / 'loading/song.mp3').write_bytes(b'fixture-audio')
        self.destination = self.root / 'state/www'

    def test_import_filters_applications_and_archives_and_verifies_every_byte(self):
        for name in ('images/index.php', 'vrp_images/index.html', 'vrp_images/source.psd', 'vrp_images/archive.rar', 'images/.DS_Store'):
            (self.source / name).write_bytes(b'not-public')
        (self.source / 'smartphone').mkdir()
        (self.source / 'smartphone/index.php').write_text('<?php fixture();')
        result = web.import_media(self.source, self.destination)
        self.assertEqual(result['files'], 3)
        self.assertEqual(result['excluded'], 5)
        self.assertEqual(web.verify_media(self.destination), {'verified': 3})
        self.assertFalse((self.destination / 'smartphone').exists())
        self.assertEqual((self.destination / 'images/item.png').stat().st_mode & 0o777, 0o644)
        (self.destination / 'images/item.png').write_bytes(b'tampered')
        with self.assertRaises(ValueError):
            web.verify_media(self.destination)
        with self.assertRaises(ValueError):
            web.import_media(self.source, self.destination)

    def test_resume_and_manifest_does_not_get_served(self):
        web.import_media(self.source, self.destination)
        web.import_media(self.source, self.destination)
        self.assertEqual(len(web.inventory(self.destination)), 3)
        self.assertTrue(self.destination.with_name('www.manifest.json').is_file())
        (self.destination / 'images/leak.php').write_text('private fixture')
        with self.assertRaises(ValueError):
            web.verify_media(self.destination)

    def test_rejects_source_and_destination_links(self):
        (self.source / 'images/link.png').symlink_to(self.source / 'images/item.png')
        with self.assertRaises(ValueError):
            web.import_media(self.source, self.destination)
        (self.source / 'images/link.png').unlink()
        self.destination.parent.mkdir()
        self.destination.symlink_to(self.source, target_is_directory=True)
        with self.assertRaises(ValueError):
            web.import_media(self.source, self.destination)

    def test_render_handles_json_lua_and_bundles_without_touching_custom_cdn(self):
        web.import_media(self.source, self.destination)
        release = self.root / 'release'
        resources = release / 'resources'
        resources.mkdir(parents=True)
        (resources / 'config.json').write_text(json.dumps({'url': 'http://127.0.0.1/vrp_images/'}))
        (resources / 'shared.lua').write_bytes(b'-- legacy encoding \xe7\r\nurl="http://127.0.0.1/images/"\r\n')
        (resources / 'bundle.js').write_text('const img=`http://127.0.0.1/images/${e[0].image}.PNG`;')
        custom = resources / 'custom.js'
        custom.write_text('const img="https://cdn.example.invalid/images/item.png";')
        original = custom.read_bytes()
        result = web.configure_release(release, 'https://city.example.invalid/', self.destination)
        self.assertEqual(result['configured'], 3)
        self.assertEqual(json.loads((resources / 'config.json').read_text())['url'], 'https://city.example.invalid/vrp_images/')
        self.assertIn(b'\xe7\r\n', (resources / 'shared.lua').read_bytes())
        self.assertIn('${e[0].image}.png', (resources / 'bundle.js').read_text())
        self.assertEqual(custom.read_bytes(), original)
        self.assertEqual(web.configure_release(release, 'https://city.example.invalid', self.destination), result)
        with self.assertRaises(ValueError):
            web.configure_release(release, 'https://other.example.invalid', self.destination)

    def test_rejects_private_origin_injection_and_http(self):
        for value in ('http://example.invalid', 'https://user:password@example.invalid',
                      'https://example.invalid/?token=fixture', 'https://example.invalid/#fixture',
                      'https://example.invalid/images/', 'https://example.invalid\nsetr bad yes',
                      'https://127.0.0.1', 'https://example.invalid:99999'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                web.base_url(value)

    def test_requires_verified_media_and_refuses_checkout_edits(self):
        release = self.root / 'release'
        (release / 'resources').mkdir(parents=True)
        config = release / 'resources/config.lua'
        config.write_text('url="http://127.0.0.1/images/"')
        with self.assertRaises(OSError):
            web.configure_release(release, 'https://city.example.invalid', self.destination)
        self.assertIn('127.0.0.1', config.read_text())
        (release / '.git').mkdir()
        with self.assertRaises(ValueError):
            web.configure_release(release, 'https://city.example.invalid')


if __name__ == '__main__':
    unittest.main()
