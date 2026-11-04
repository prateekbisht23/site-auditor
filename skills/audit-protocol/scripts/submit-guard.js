// site-auditor submit guard. Evaluate in the page after every navigation.
// Blocks form submission and state-changing requests (non-GET/HEAD) originating from
// the page, and logs each attempt to window.__SA_BLOCKED for the auditor to read.
(() => {
  if (window.__SA_GUARD) return 'guard already active';
  window.__SA_GUARD = true;
  window.__SA_BLOCKED = [];
  const log = (type, detail) => {
    window.__SA_BLOCKED.push({ type, detail, at: new Date().toISOString() });
  };
  const SAFE = new Set(['GET', 'HEAD', 'OPTIONS']);

  // 1. Form submissions (event + programmatic)
  document.addEventListener('submit', (e) => {
    e.preventDefault(); e.stopImmediatePropagation();
    log('form-submit', e.target && (e.target.action || e.target.id || 'form'));
  }, true);
  HTMLFormElement.prototype.submit = function () { log('form.submit()', this.action || this.id); };
  HTMLFormElement.prototype.requestSubmit = function () { log('form.requestSubmit()', this.action || this.id); };

  // 2. fetch
  const origFetch = window.fetch;
  window.fetch = function (input, init = {}) {
    const method = String(init.method || (input && input.method) || 'GET').toUpperCase();
    const url = typeof input === 'string' ? input : (input && input.url) || String(input);
    if (!SAFE.has(method)) {
      log('fetch-blocked', `${method} ${url}`);
      return Promise.reject(new TypeError(`[site-auditor] blocked ${method} ${url}`));
    }
    return origFetch.apply(this, arguments);
  };

  // 3. XHR
  const origOpen = XMLHttpRequest.prototype.open;
  const origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__sa = { method: String(method).toUpperCase(), url: String(url) };
    return origOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function () {
    if (this.__sa && !SAFE.has(this.__sa.method)) {
      log('xhr-blocked', `${this.__sa.method} ${this.__sa.url}`);
      this.abort();
      return;
    }
    return origSend.apply(this, arguments);
  };

  // 4. sendBeacon is POST by definition (mostly analytics): log, allow nothing.
  if (navigator.sendBeacon) {
    navigator.sendBeacon = (url) => { log('beacon-blocked', String(url)); return true; };
  }
  return 'guard active';
})();
