/* SH 인력관리 — 홈 화면 설치(PWA)용 서비스 워커.
   화면(index.html)은 항상 네트워크에서 먼저 받고, 오프라인일 때만 마지막으로 받은 화면을 보여 준다.
   캐시 우선이 아니므로 배포한 새 화면이 바로 반영된다. */
const CACHE = 'sh-wf-v1';
const SHELL = ['./', './index.html', './icon-192.png', './manifest.webmanifest'];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(SHELL).catch(() => {}))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;

  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then(res => {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put('./index.html', copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  event.respondWith(fetch(req).catch(() => caches.match(req)));
});
