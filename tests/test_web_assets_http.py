"""Opt-in integration against the exact Caddy image already used in production."""
import http.client
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.environ.get('IC_TEST_CADDY') == '1', 'Set IC_TEST_CADDY=1 to run the isolated Caddy HTTP test')
class WebAssetsHTTPTests(unittest.TestCase):
    def test_media_routes_ranges_and_game_proxy_are_separate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            config = root / 'caddy'
            shutil.copytree(ROOT / 'docker/caddy', config)
            media = root / 'www'
            for group in ('images', 'vrp_images', 'loading'):
                (media / group).mkdir(parents=True)
            image = b'fixture-png-image'
            video = b'fixture-video-for-range-requests'
            (media / 'images/item.png').write_bytes(image)
            (media / 'vrp_images/car.png').write_bytes(image)
            (media / 'loading/video.mp4').write_bytes(video)
            # Even if mistakenly copied, applications and manifests must not be served.
            (media / 'images/index.php').write_text('private fixture')
            (media / 'images/index.html').write_text('private fixture')
            (media / 'images/manifest.json').write_text('{}')
            name = 'interior-city-assets-test-' + uuid.uuid4().hex[:12]
            command = ['docker', 'run', '--rm', '-d', '--name', name,
                       '--network', 'bridge', '-p', '127.0.0.1::8080',
                       '-e', 'CADDY_DOMAIN=http://:8080',
                       '-v', f'{config}:/etc/caddy:ro', '-v', f'{media}:/srv/www:ro',
                       'caddy:2.10.2-alpine']
            try:
                subprocess.run(command, check=True, capture_output=True, text=True, timeout=60)
                port = subprocess.run(['docker', 'inspect', name, '--format',
                                       '{{json .NetworkSettings.Ports}}'], check=True,
                                      capture_output=True, text=True, timeout=15)
                port = int(json.loads(port.stdout)['8080/tcp'][0]['HostPort'])

                def request(path, method='GET', headers=None):
                    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
                    try:
                        connection.request(method, path, headers=headers or {})
                        response = connection.getresponse()
                        return response.status, dict(response.getheaders()), response.read()
                    finally:
                        connection.close()

                for attempt in range(30):
                    try:
                        response = request('/images/item.png')
                        break
                    except (OSError, http.client.HTTPException):
                        time.sleep(0.1)
                else:
                    self.fail('Caddy did not become ready')
                self.assertEqual(response[0], 200)
                self.assertEqual(response[2], image)
                self.assertEqual(response[1]['Access-Control-Allow-Origin'], '*')
                self.assertEqual(response[1]['X-Content-Type-Options'], 'nosniff')
                self.assertEqual(request('/vrp_images/car.png')[2], image)
                self.assertEqual(request('/images/item.png', 'HEAD')[2], b'')
                status, headers, body = request('/loading/video.mp4', headers={'Range': 'bytes=0-6'})
                self.assertEqual(status, 206)
                self.assertEqual(body, video[:7])
                for path in ('/images/missing.png', '/images/', '/images/index.php',
                             '/images/index.html', '/images/manifest.json'):
                    self.assertEqual(request(path)[0], 404, path)
                # The game upstream is absent in this isolated test: 502 proves fallback.
                self.assertEqual(request('/info.json')[0], 502)
                self.assertEqual(request('/images/item.png', 'POST')[0], 404)
            finally:
                subprocess.run(['docker', 'rm', '-f', name], capture_output=True, timeout=15)


if __name__ == '__main__':
    unittest.main()
