const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const loader = fs.readFileSync(path.join(__dirname, 'partner_web_bootstrap.js'), 'utf8');
const recovery = fs.readFileSync(path.join(__dirname, 'partner_web_404.html'), 'utf8')
  .match(/<script>([\s\S]*?)<\/script>/)[1];
const oldBuild = '012345abcdef';
const newBuild = 'fedcba987654';
const release = (build) => ({build, release_base: `/Go-Partner/releases/${build}/`});

function browser(t, {url = 'https://example.test/Go-Partner/', version = release(newBuild)} = {}) {
  let currentUrl = new URL(url);
  let response = version;
  const timers = new Set();
  const scripts = [];
  const requests = [];
  const navigations = [];
  const unregistered = [];
  const buildMeta = {content: oldBuild};
  const base = {href: release(oldBuild).release_base};
  const retry = {hidden: true};
  const localStorage = new Map([['session', 'keep-signed-in']]);
  function events() {
    const listeners = new Map();
    return {
      addEventListener(name, callback) {
        listeners.set(name, [...(listeners.get(name) || []), callback]);
      },
      async emit(name) {
        await Promise.all((listeners.get(name) || []).map((callback) => callback({type: name})));
      },
    };
  }
  const window = events();
  const document = {
    ...events(),
    visibilityState: 'visible',
    get baseURI() { return new URL(base.href, currentUrl).href; },
    querySelector(selector) { return selector === 'base' ? base : buildMeta; },
    getElementById(id) { return id === 'go-partner-retry' ? retry : {remove() {}}; },
    createElement() { return {}; },
    body: {appendChild(script) { scripts.push(script); }},
  };
  const location = {
    get href() { return currentUrl.href; },
    get pathname() { return currentUrl.pathname; },
    get origin() { return currentUrl.origin; },
    get search() { return currentUrl.search; },
    get hash() { return currentUrl.hash; },
    replace(target) { navigations.push(target); currentUrl = new URL(target); },
  };
  const context = vm.createContext({
    window, document, location, URL, AbortController, localStorage,
    history: {state: null, replaceState(state, unused, target) { currentUrl = new URL(target, currentUrl); }},
    navigator: {serviceWorker: {async getRegistrations() {
      return ['/Go-Partner/', '/Go-Partner/releases/old/', '/Go-Customer/', '/'].map((scope) => ({
        scope: `https://example.test${scope}`,
        async unregister() { unregistered.push(scope); return true; },
      }));
    }}},
    async fetch(url, options) {
      requests.push({url, options});
      if (response instanceof Error) throw response;
      if (response === 'timeout') {
        return new Promise((resolve, reject) => {
          options.signal.addEventListener('abort', () => reject(new Error('aborted')));
        });
      }
      return {ok: true, async json() { return response; }};
    },
    setTimeout(callback, delay) {
      const timer = setTimeout(callback, delay);
      timers.add(timer);
      return timer;
    },
    clearTimeout(timer) { clearTimeout(timer); timers.delete(timer); },
  });
  t.after(() => { for (const timer of timers) clearTimeout(timer); });
  return {
    context, document, window, location, scripts, requests, navigations,
    unregistered, buildMeta, localStorage,
    setVersion(value) { response = value; },
    async start() {
      await vm.runInContext(loader, context);
      await window.emit('flutter-first-frame');
    },
  };
}

test('cached root HTML loads the latest bootstrap before Flutter starts', async (t) => {
  const page = browser(t);
  await page.start();
  assert.equal(page.scripts.length, 1);
  assert.equal(page.scripts[0].src, `https://example.test${release(newBuild).release_base}flutter_bootstrap.js`);
  assert.equal(page.buildMeta.content, newBuild);
  assert.equal(page.requests[0].options.cache, 'no-store');
  assert.match(page.requests[0].url, /^\/Go-Partner\/version.json\?t=\d+$/);
  assert.deepEqual(page.navigations, []);
  assert.equal(page.localStorage.get('session'), 'keep-signed-in');
});

test('release bookmarks normalize to the stable root and preserve routes', async (t) => {
  const page = browser(t, {url: `https://example.test${release(oldBuild).release_base}?lang=ar#/orders`});
  await page.start();
  assert.equal(page.location.href, 'https://example.test/Go-Partner/?lang=ar#/orders');
  assert.equal(page.buildMeta.content, newBuild);
});

test('returning to a Home Screen session updates once without a redirect loop', async (t) => {
  const page = browser(t, {version: release(oldBuild), url: 'https://example.test/Go-Partner/?lang=ar#/orders'});
  await page.start();
  page.setVersion(release(newBuild));
  await page.window.emit('pageshow');
  await page.window.emit('online');
  await page.document.emit('visibilitychange');
  assert.equal(page.navigations.length, 1);
  const target = new URL(page.navigations[0]);
  assert.equal(target.pathname, '/Go-Partner/');
  assert.equal(target.searchParams.get('v'), newBuild);
  assert.equal(target.searchParams.get('lang'), 'ar');
  assert.equal(target.hash, '#/orders');
});

test('same-version returns keep the current screen in place', async (t) => {
  const page = browser(t);
  await page.start();
  await page.window.emit('pageshow');
  await page.document.emit('visibilitychange');
  assert.deepEqual(page.navigations, []);
});

test('background sessions wait until visible before updating', async (t) => {
  const page = browser(t, {version: release(oldBuild)});
  await page.start();
  page.setVersion(release(newBuild));
  page.document.visibilityState = 'hidden';
  await page.window.emit('online');
  assert.equal(page.requests.length, 1);
  page.document.visibilityState = 'visible';
  await page.document.emit('visibilitychange');
  assert.equal(page.navigations.length, 1);
});

test('offline launch uses bundled assets and retries the version check on reconnection', async (t) => {
  const page = browser(t, {version: new Error('offline')});
  await page.start();
  assert.equal(page.scripts[0].src, `https://example.test${release(oldBuild).release_base}flutter_bootstrap.js`);
  page.setVersion(release(newBuild));
  await page.window.emit('online');
  assert.equal(page.navigations.length, 1);
});

test('invalid release paths cannot select foreign scripts', async (t) => {
  const page = browser(t, {version: {build: newBuild, release_base: 'https://another.test/'}});
  await page.start();
  assert.equal(page.buildMeta.content, oldBuild);
  assert.equal(page.scripts[0].src, `https://example.test${release(oldBuild).release_base}flutter_bootstrap.js`);
});

test('a hanging version check times out and still starts the bundled app', {timeout: 5000}, async (t) => {
  const page = browser(t, {version: 'timeout'});
  await page.start();
  assert.equal(page.requests[0].options.signal.aborted, true);
  assert.equal(page.scripts[0].src, `https://example.test${release(oldBuild).release_base}flutter_bootstrap.js`);
});

test('worker retirement leaves other apps and login storage untouched', async (t) => {
  const page = browser(t);
  await page.start();
  assert.deepEqual(page.unregistered, ['/Go-Partner/', '/Go-Partner/releases/old/']);
  assert.equal(page.localStorage.get('session'), 'keep-signed-in');
});

test('retired release pages recover while missing assets remain errors', (t) => {
  const oldPage = browser(t, {url: `https://example.test${release(oldBuild).release_base}index.html#/orders`});
  vm.runInContext(recovery, oldPage.context);
  assert.equal(oldPage.navigations.length, 1);
  assert.equal(new URL(oldPage.navigations[0]).pathname, '/Go-Partner/');
  assert.equal(new URL(oldPage.navigations[0]).hash, '#/orders');
  const withoutSlash = browser(t, {url: `https://example.test/Go-Partner/releases/${oldBuild}`});
  vm.runInContext(recovery, withoutSlash.context);
  assert.equal(withoutSlash.navigations.length, 1);
  const missingAsset = browser(t, {url: `https://example.test${release(oldBuild).release_base}missing.js`});
  vm.runInContext(recovery, missingAsset.context);
  assert.deepEqual(missingAsset.navigations, []);
});
