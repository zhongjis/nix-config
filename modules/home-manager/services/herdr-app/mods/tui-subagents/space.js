// Which space a sub-agent works for, so it stays findable after its parent's pane closes: its own `space` label
// (set by the orchestrator skill's start-worker.sh and by a revive), else the nearest ancestor's `space` or
// `herdr.space` (a terminal with a pane). A copy lives in each mod that uses it, as tree.js does.

export function spaceOf(k, byAddress) {
  for (let n = 0; k && n < 16; n++, k = byAddress.get(k.parent)) {
    const s = k.labels?.space ?? k.labels?.["herdr.space"];
    if (s) return s;
  }
  return null;
}

// Live sub-agents working for `space`, depth first, each with its depth under the topmost one there.
export function inSpace(all, space) {
  const byAddress = new Map(all.map((k) => [k.address, k]));
  const mine = all.filter((k) => k.parent && k.state === "live" && spaceOf(k, byAddress) === space);
  const ids = new Set(mine.map((k) => k.address));
  const walk = (k, depth) => [{ k, depth }, ...mine.filter((c) => c.parent === k.address).flatMap((c) => walk(c, depth + 1))];
  return mine.filter((k) => !ids.has(k.parent)).flatMap((k) => walk(k, 0));
}
