"""Generate a content-aware cache: unchanged WASM survives game-only updates.

HTML is network-first; exported binary files are cache-first under their content
hash, not under a single stale game-version cache. No speculative predownloads.
"""
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
hashes = {
    p.name: hashlib.sha256(p.read_bytes()).hexdigest()
    for p in sorted(root.iterdir())
    if p.is_file() and p.name != 'cache-worker.js' and p.suffix in {'.wasm', '.pck', '.js', '.png'}
}
worker = """const HASHES = __HASHES__;
const CACHE = 'crossroads-content-v1';
const keyFor = (name) => new URL('./__cached__/' + HASHES[name] + '/' + name, self.location).href;
self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
self.addEventListener('activate', event => event.waitUntil((async()=>{
  const cache = await caches.open(CACHE);
  const wanted = new Set(Object.keys(HASHES).map(keyFor));
  for(const request of await cache.keys()) if(!wanted.has(request.url)) await cache.delete(request);
  await self.clients.claim();
})()));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url), base = new URL('./', self.location);
  if(event.request.method !== 'GET' || url.origin !== base.origin || !url.pathname.startsWith(base.pathname)) return;
  const name = url.pathname.slice(base.pathname.length);
  if(!HASHES[name]) return;
  event.respondWith((async()=>{
    const cache = await caches.open(CACHE), key = keyFor(name);
    const hit = await cache.match(key);
    if(hit) return hit;
    const response = await fetch(event.request, {cache: 'no-cache'});
    if(response.ok) {
      const bytes = await response.clone().arrayBuffer();
      const digest = await crypto.subtle.digest('SHA-256', bytes);
      const actual = [...new Uint8Array(digest)].map(n=>n.toString(16).padStart(2,'0')).join('');
      if(actual === HASHES[name]) await cache.put(key, response.clone());
    }
    return response;
  })().catch(()=>fetch(event.request)));
});
""".replace('__HASHES__', json.dumps(hashes, sort_keys=True))
(root / 'cache-worker.js').write_text(worker)
print(f'Cache manifest: {len(hashes)} files, content-addressed engine reuse')
