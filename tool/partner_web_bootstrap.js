// This loader is inlined into the entry page so even a cached entry page can
// select the latest complete release before starting Flutter.
(async function () {
  const appRoot = '/Go-Partner/';
  const buildMeta = document.querySelector('meta[name="go-partner-build"]');
  let runningBuild = buildMeta.content;
  let launching = true;
  let checking = false;
  let navigating = false;

  async function latestRelease() {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    try {
      const response = await fetch(`${appRoot}version.json?t=${Date.now()}`, {
        cache: 'no-store',
        signal: controller.signal,
      });
      if (!response.ok) return null;
      const release = await response.json();
      if (typeof release.build !== 'string' ||
          !/^[A-Za-z0-9_-]{1,64}$/.test(release.build) ||
          release.release_base !== `${appRoot}releases/${release.build}/`) {
        return null;
      }
      return release;
    } catch (_) {
      // An unavailable update check must not prevent the bundled app opening.
      return null;
    } finally {
      clearTimeout(timeout);
    }
  }

  async function retireOldWorker() {
    if (!('serviceWorker' in navigator)) return;
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.filter((registration) => {
        const scope = new URL(registration.scope);
        return scope.origin === location.origin && scope.pathname.startsWith(appRoot);
      }).map((registration) => registration.unregister()));
    } catch (_) {}
  }

  async function checkOnReturn() {
    if (launching || checking || navigating || document.visibilityState === 'hidden') return;
    checking = true;
    try {
      const latest = await latestRelease();
      if (!latest || latest.build === runningBuild || document.visibilityState === 'hidden') return;
      navigating = true;
      const target = new URL(appRoot, location.origin);
      target.search = location.search;
      target.searchParams.set('v', latest.build);
      target.searchParams.set('launch', String(Date.now()));
      target.hash = location.hash;
      location.replace(target.href);
    } finally {
      checking = false;
    }
  }

  window.addEventListener('pageshow', checkOnReturn);
  window.addEventListener('online', checkOnReturn);
  document.addEventListener('visibilitychange', checkOnReturn);

  // The old worker only knows old asset URLs. New versioned URLs bypass those
  // entries; unregister it without deleting shared caches, cookies or login data.
  void retireOldWorker();
  const latest = await latestRelease();
  if (latest) {
    runningBuild = latest.build;
    document.querySelector('base').href = latest.release_base;
    buildMeta.content = runningBuild;
  }

  // Keep bookmarks and future Home Screen additions on the stable entry URL.
  if (location.pathname.startsWith(`${appRoot}releases/`)) {
    history.replaceState(history.state, '', `${appRoot}${location.search}${location.hash}`);
  }

  const opening = document.getElementById('go-partner-opening');
  const retry = document.getElementById('go-partner-retry');
  const showRetry = () => { if (retry) retry.hidden = false; };
  const startupTimeout = setTimeout(showRetry, 15000);
  window.addEventListener('flutter-first-frame', () => {
    clearTimeout(startupTimeout);
    opening?.remove();
  }, {once: true});
  const script = document.createElement('script');
  script.src = new URL('flutter_bootstrap.js', document.baseURI).href;
  script.async = true;
  script.onerror = showRetry;
  document.body.appendChild(script);
  launching = false;
})();
