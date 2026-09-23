# GO Partner web preview

Share and save this stable URL: https://omarmakramelbaz-hub.github.io/Go-Partner/?launch=home

The manifest uses `/Go-Partner/` for its identity and scope. Its stable Home
Screen start URL adds `?launch=home` to bypass older cached root HTML on the
first launch; this value does not change between releases. The manifest and
Apple touch icon are available at the root, even when the page was opened
through a release URL.

Before starting Flutter, the entry page requests `version.json` without using
the HTTP cache and with a timestamp in the URL. It loads the selected release's
bootstrap, code and assets together. This also works when the entry HTML itself
is cached. Returning from a suspended Home Screen session, browser back/forward
cache, or offline state checks the version again. A changed version reopens the
stable URL; the same version leaves the current screen in place.

Release URLs are build artifacts, not installation links. Current release URLs
are normalized to the root. Retired release bookmarks recover through the
custom 404 page; missing asset requests remain errors.

An existing iPhone shortcut installed with the old empty manifest may still
retain an old URL or an already-running page without the new loader. Open the
stable URL in Safari and replace that old Home Screen shortcut once. Code
deployed today cannot change a cached page until the device loads it.

Worker cleanup is restricted to `/Go-Partner/`. It does not delete shared-origin
caches, cookies, local storage or IndexedDB. Native mobile releases and Apple
submissions are independent of this web-only startup change.

Regression checks:

```sh
python3 -m unittest discover -s tool -p test_package_partner_web.py
node --test tool/test_web_bootstrap.cjs
```
