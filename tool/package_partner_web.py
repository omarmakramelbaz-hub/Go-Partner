"""Publish each Flutter build, including its assets, under a unique URL.

Changing only main.dart.js leaves logos and images at cacheable, unversioned
URLs. The root index always points to a complete, commit-specific release.
"""

import json
import os
import re
import shutil
from pathlib import Path


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
    ):
        path = source / asset
        if not path.is_file() or not path.stat().st_size:
            raise SystemExit(f'Required web asset is missing: {asset}')

    opening = '''
  <style>
    html, body { margin: 0; width: 100%; height: 100%; background: #171a1f; }
    #go-partner-opening { position: fixed; inset: 0; z-index: 2147483647;
      background: #171a1f url(assets/assets/brand/partner_splash.webp) center/cover;
      display: flex; align-items: center; justify-content: center;
      padding-bottom: 22vh; box-sizing: border-box; }
    #go-partner-opening img { width: min(50vw, 220px); object-fit: contain; }
  </style>
  <div id="go-partner-opening"><img src="assets/assets/svg/go_partner_logo_light.svg" alt="GO Partner"></div>
  <script>
    (async function () {
      // Retire only this app's workers. Other apps share this GitHub Pages origin.
      try {
        if ('serviceWorker' in navigator) {
          const regs = await navigator.serviceWorker.getRegistrations();
          await Promise.all(regs.filter((r) =>
            new URL(r.scope).pathname.startsWith('/Go-Partner/')
          ).map((r) => r.unregister()));
        }
      } catch (_) {}
      const removeOpening = () => document.getElementById('go-partner-opening')?.remove();
      window.addEventListener('flutter-first-frame', removeOpening, {once: true});
      const script = document.createElement('script');
      script.src = 'flutter_bootstrap.js';
      script.async = true;
      document.body.appendChild(script);
      setTimeout(removeOpening, 10000);
    })();
  </script>'''
    original = '<script src="flutter_bootstrap.js" async></script>'
    if html.count(original) != 1:
        raise SystemExit('Expected exactly one Flutter bootstrap script')
    html = html.replace(original, opening).replace(
        '</head>', f'<meta name="go-partner-build" content="{build}">\n</head>'
    )
    if destination.exists():
        shutil.rmtree(destination)
    release = destination / 'releases' / build
    shutil.copytree(source, release)
    (release / 'index.html').write_text(html, encoding='utf-8')
    (destination / 'index.html').write_text(html, encoding='utf-8')
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
