"""Publish each Flutter build, including its assets, under a unique URL.

The stable entry point selects the latest complete release even when its HTML
was cached. Home Screen installations always start at that stable URL.
"""

import json
import os
import re
import shutil
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
APP_ROOT = '/Go-Partner/'
APP_START = APP_ROOT + '?launch=home'


def package_web():
    build = os.environ.get('GITHUB_SHA', 'local')[:12]
    if not re.fullmatch(r'[A-Za-z0-9_-]+', build):
        raise SystemExit('Invalid build identifier')
    source = Path('build/web')
    destination = Path('build/pages')
    release_base = f'/Go-Partner/releases/{build}/'
    html = (source / 'index.html').read_text(encoding='utf-8')
    if f'<base href="{release_base}">' not in html:
        raise SystemExit(f'Build web with --base-href "{release_base}" first')

    for asset in (
        'main.dart.js',
        'flutter_bootstrap.js',
        'assets/assets/svg/go_partner_logo.svg',
        'assets/assets/svg/go_partner_logo_light.svg',
        'assets/assets/brand/partner_splash.webp',
        'assets/assets/brand/partner_welcome.webp',
        'assets/assets/images/go_partner_app_icon.png',
    ):
        path = source / asset
        if not path.is_file() or not path.stat().st_size:
            raise SystemExit(f'Required web asset is missing: {asset}')

    opening = '''
  <style>
    html, body { margin: 0; width: 100%; height: 100%; background: #171a1f; }
    #go-partner-opening { position: fixed; inset: 0; z-index: 2147483647;
      background: #171a1f url(assets/assets/brand/partner_splash.webp) center/cover;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      padding-bottom: 22vh; box-sizing: border-box; }
    #go-partner-opening img { width: min(50vw, 220px); object-fit: contain; }
    #go-partner-retry { color: white; text-align: center; font: 16px sans-serif; }
    #go-partner-retry button { padding: 12px 24px; border: 0; border-radius: 12px; background: #ff7900; color: white; }
  </style>
  <div id="go-partner-opening">
    <img src="/Go-Partner/partner-logo.svg" alt="GO Partner">
    <div id="go-partner-retry" role="alert" hidden>
      <p>تعذر فتح التطبيق. تحقق من الاتصال وحاول مرة أخرى.</p>
      <button onclick="location.reload()">إعادة المحاولة</button>
    </div>
  </div>
  <script>''' + (TOOLS / 'partner_web_bootstrap.js').read_text() + '</script>'
    original = '<script src="flutter_bootstrap.js" async></script>'
    if html.count(original) != 1:
        raise SystemExit('Expected exactly one Flutter bootstrap script')
    html = html.replace(original, opening)
    html = re.sub(r'<link\b[^>]*\brel="(?:manifest|apple-touch-icon|icon)"[^>]*>', '', html)
    html = re.sub(r'<meta\b[^>]*name="apple-mobile-web-app-title"[^>]*>', '', html)
    html = re.sub(r'<title>.*?</title>', '<title>GO Partner</title>', html)
    html = html.replace('</head>', f'''
  <meta name="go-partner-build" content="{build}">
  <meta name="apple-mobile-web-app-title" content="GO Partner">
  <meta name="theme-color" content="#171a1f">
  <link rel="manifest" href="{APP_ROOT}manifest.json">
  <link rel="apple-touch-icon" href="{APP_ROOT}icons/go-partner.png">
  <link rel="icon" type="image/png" href="{APP_ROOT}icons/go-partner.png">
</head>''')
    manifest = json.loads((source / 'manifest.json').read_text())
    if (any(manifest.get(key) != APP_ROOT for key in ('id', 'scope'))
            or manifest.get('start_url') != APP_START):
        raise SystemExit('Home Screen identity and start URL must use the stable app root')
    if destination.exists():
        shutil.rmtree(destination)
    release = destination / 'releases' / build
    shutil.copytree(source, release)
    (release / 'index.html').write_text(html, encoding='utf-8')
    (destination / 'index.html').write_text(html, encoding='utf-8')
    (destination / 'manifest.json').write_text(json.dumps(manifest) + '\n')
    (destination / 'icons').mkdir()
    shutil.copyfile(source / 'assets/assets/images/go_partner_app_icon.png',
                    destination / 'icons/go-partner.png')
    shutil.copyfile(source / 'assets/assets/svg/go_partner_logo_light.svg',
                    destination / 'partner-logo.svg')
    shutil.copyfile(TOOLS / 'partner_web_404.html', destination / '404.html')
    (destination / '.nojekyll').touch()
    (destination / 'version.json').write_text(
        json.dumps({'build': build, 'release_base': release_base}) + '\n',
        encoding='utf-8',
    )
    # Existing installations may still ask for the old service worker URL.
    # This worker takes over without caching and then unregisters itself.
    (destination / 'flutter_service_worker.js').write_text('''
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil((async () => {
  await self.clients.claim();
  await self.registration.unregister();
})()));
''', encoding='utf-8')
    print(f'Packaged GO Partner {build}: {destination}')


if __name__ == '__main__':
    package_web()
