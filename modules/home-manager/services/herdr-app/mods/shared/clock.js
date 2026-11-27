// When each agent last changed status, for ages and pulses. Pure: the `hc get` fetch is injected, so node tests
// run it (bd.js statusMs is the real one). terminals().status_ms is only right as of the app's start.
//
// API
//   new Clock(fetchMs, onChange?)
//        fetchMs(address)   async -> the core's status_ms (epoch ms) for that terminal, or null/undefined; a reject
//                           counts as null. Called once per address, on first sight.
//        onChange()         called when a fetch answered and moved a time (so a mod can redraw).
//   clock.observe(address, status, stale, now = Date.now())
//        Call on each render for each agent. First sight: since = `stale` (terminals() status_ms, 0 when unknown)
//        until the fetch answers, then the fetch's value (unless a change was seen meanwhile). A later status change
//        sets since = now and records a flip. The first sight's fetch starts at once (not in a later microtask).
//   clock.takePending()   the fetches started since the last call (promises that settle when each answered and
//                         was applied), so a render can redraw once they land: await them in a task, then notify.
//   clock.since(address)  epoch ms of the last change, 0 when unknown or never observed.
//   clock.flip(address)   the last change seen { from, to, at }, or undefined (first sight is no flip).
//   clock.prune(addresses)  forgets every address not in the iterable.

export class Clock {
  constructor(fetchMs, onChange) {
    this.fetchMs = fetchMs;
    this.onChange = onChange;
    this.entries = new Map();
    this.pending = [];
  }

  observe(address, status, stale, now = Date.now()) {
    const e = this.entries.get(address);
    if (!e) {
      const fresh = { status, since: Number.isFinite(stale) ? stale : 0, flip: undefined, changed: false };
      this.entries.set(address, fresh);
      let asked;
      try {
        asked = Promise.resolve(this.fetchMs(address));
      } catch {
        asked = Promise.resolve(null);
      }
      this.pending.push(asked.catch(() => null).then((ms) => {
        if (fresh.changed || !Number.isFinite(ms) || ms <= 0 || this.entries.get(address) !== fresh) return;
        fresh.since = ms;
        this.onChange?.();
      }));
      return;
    }
    if (e.status !== status) {
      e.flip = { from: e.status, to: status, at: now };
      e.status = status;
      e.since = now;
      e.changed = true;
    }
  }

  takePending() {
    const out = this.pending;
    this.pending = [];
    return out;
  }

  since(address) {
    return this.entries.get(address)?.since ?? 0;
  }

  flip(address) {
    return this.entries.get(address)?.flip;
  }

  prune(addresses) {
    const keep = new Set(addresses);
    for (const a of this.entries.keys()) if (!keep.has(a)) this.entries.delete(a);
  }
}
