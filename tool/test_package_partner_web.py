import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from package_partner_web import package_web

ROOT = Path(__file__).resolve().parents[1]
BUILD = '012345abcdef'
ASSETS = (
    'main.dart.js',
    'flutter_bootstrap.js',
    'assets/assets/svg/go_partner_logo.svg',
    'assets/assets/svg/go_partner_logo_light.svg',
    'assets/assets/brand/partner_splash.webp',
    'assets/assets/brand/partner_welcome.webp',
    'assets/assets/images/go_partner_app_icon.png',
)


class WebPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.previous = Path.cwd()
        os.chdir(self.temporary.name)
        self.source = Path('build/web')
        self.source.mkdir(parents=True)
        self.html = f'''<!doctype html><html><head>
<base href="/Go-Partner/releases/{BUILD}/">
<title>go_partner</title>
<meta name="apple-mobile-web-app-title" content="go_partner">
<link rel="manifest" href="manifest.json">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
<link rel="icon" type="image/png" href="favicon.png"/>
</head><body><script src="flutter_bootstrap.js" async></script></body></html>'''
        (self.source / 'index.html').write_text(self.html)
        (self.source / 'manifest.json').write_text((ROOT / 'web/manifest.json').read_text())
        for name in ASSETS:
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'asset fixture')
        self.environment = patch.dict(os.environ, {'GITHUB_SHA': BUILD})
        self.environment.start()

    def tearDown(self):
        self.environment.stop()
        os.chdir(self.previous)
        self.temporary.cleanup()

    def test_root_and_release_install_the_same_stable_app(self):
        package_web()
        pages = Path('build/pages')
        root = (pages / 'index.html').read_text()
        release = (pages / f'releases/{BUILD}/index.html').read_text()
        self.assertEqual(root, release)
        self.assertIn('fetch(`${appRoot}version.json?t=${Date.now()}`', root)
        self.assertEqual(root.count('rel="manifest"'), 1)
        self.assertIn('href="/Go-Partner/manifest.json"', root)
        self.assertIn('href="/Go-Partner/icons/go-partner.png"', root)
        self.assertNotIn('href="icons/Icon-192.png"', root)
        manifest = json.loads((pages / 'manifest.json').read_text())
        for key in ('id', 'start_url', 'scope'):
            self.assertEqual(manifest[key], '/Go-Partner/')
        self.assertEqual(manifest['name'], 'GO Partner')
        self.assertTrue((pages / 'icons/go-partner.png').is_file())
        self.assertTrue((pages / 'partner-logo.svg').is_file())
        self.assertTrue((pages / '404.html').is_file())
        self.assertEqual(json.loads((pages / 'version.json').read_text()), {
            'build': BUILD, 'release_base': f'/Go-Partner/releases/{BUILD}/',
        })

    def test_new_publish_replaces_release_and_keeps_bookmark_recovery(self):
        package_web()
        next_build = 'fedcba987654'
        (self.source / 'index.html').write_text(self.html.replace(BUILD, next_build))
        with patch.dict(os.environ, {'GITHUB_SHA': next_build}):
            package_web()
        self.assertFalse(Path(f'build/pages/releases/{BUILD}').exists())
        self.assertTrue(Path(f'build/pages/releases/{next_build}/index.html').is_file())
        self.assertEqual(Path('build/pages/404.html').read_text(),
                         (ROOT / 'tool/partner_web_404.html').read_text())

    def test_release_specific_start_url_is_rejected(self):
        manifest = json.loads((self.source / 'manifest.json').read_text())
        manifest['start_url'] = f'/Go-Partner/releases/{BUILD}/'
        (self.source / 'manifest.json').write_text(json.dumps(manifest))
        with self.assertRaisesRegex(SystemExit, 'stable app root'):
            package_web()

    def test_missing_bundled_icon_is_rejected(self):
        (self.source / ASSETS[-1]).unlink()
        with self.assertRaisesRegex(SystemExit, 'Required web asset is missing'):
            package_web()


if __name__ == '__main__':
    unittest.main()
