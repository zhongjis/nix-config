// Which space a sub-agent works for, so it stays findable after its parent's pane closes: its own `space` label
// (set by the orchestrator skill's start-worker.sh and by a revive), else the nearest ancestor's `space` or
// `herdr.space` (a terminal with a pane). Where it works: its folder, matched against worktree folders.
// A copy lives in each mod that uses it, as tree.js does.

export function spaceOf(k, byAddress) {
  for (let n = 0; k && n < 16; n++, k = byAddress.get(k.parent)) {
    const s = k.labels?.space ?? k.labels?.["herdr.space"];
    if (s) return s;
  }
  return null;
}

// `cwd` is `folder` or inside it.
export const inside = (cwd, folder) => Boolean(cwd && folder) && (cwd === folder || cwd.startsWith(`${folder.replace(/\/+$/, "")}/`));

// Whether a sub-agent (live terminal or hibernated row) matches a filter: {space, folder, except: [folders]}.
export function matches(space, cwd, f) {
  return (!f.space || space === f.space) && (!f.folder || inside(cwd, f.folder)) && !(f.except ?? []).some((x) => inside(cwd, x));
}

// Live sub-agents matching the filter, depth first, each with its depth under the topmost one there.
export function inSpace(all, filter) {
  const byAddress = new Map(all.map((k) => [k.address, k]));
  const mine = all.filter((k) => k.parent && k.state === "live" && matches(spaceOf(k, byAddress), k.cwd, filter));
  const ids = new Set(mine.map((k) => k.address));
  const walk = (k, depth) => [{ k, depth }, ...mine.filter((c) => c.parent === k.address).flatMap((c) => walk(c, depth + 1))];
  return mine.filter((k) => !ids.has(k.parent)).flatMap((k) => walk(k, 0));
}

// Live main agents (no parent; the program reports a status) matching the filter, as inSpace's rows (depth 0).
// Idle and blocked count too: running is what matters here, status is tui-focus's.
export function mainIn(all, filter) {
  const byAddress = new Map(all.map((k) => [k.address, k]));
  return all.filter((k) => !k.parent && k.state === "live" && k.status && matches(spaceOf(k, byAddress), k.cwd, filter))
    .map((k) => ({ k, depth: 0 }));
}
