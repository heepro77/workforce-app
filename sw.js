/* SH 인력관리 — 홈 화면 설치(PWA)용 최소 서비스 워커.
   화면을 캐시하지 않고 그대로 네트워크로 보낸다: 항상 최신 index.html 을 연다. */
self.addEventListener('install', () => { self.skipWaiting(); });
self.addEventListener('activate', event => { event.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(fetch(event.request, { cache: 'no-store' }).catch(() => caches.match(event.request)));
});
