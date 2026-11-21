// Where a click or a cleanup lands in a space: its first terminal, and a folder that still exists to open one in
// (a removed worktree's doesn't). One source here, linked into each mod that uses it; Nix copies it into each mod
// folder (Herdr refuses imports from outside a mod's folder).
import { exec } from "herdr";

// A space's first terminal that isn't an agent (a busy shell, nvim or a server counts): its shown tab first, then
// tab order. `ps`: panes(), read once by the caller.
export function firstTerminal(s, ps) {
  const tabs = [...(s.tabs ?? [])].sort((a, b) => Number(b.active) - Number(a.active));
  for (const t of tabs) {
    const p = ps.find((p) => p.tab === t.id && p.terminal && !p.status && !p.program?.agent);
    if (p) return p;
  }
  return null;
}

// The first of `folders` that exists on that machine (`on`: null is this one); null when none does or it can't be asked.
export const firstFolder = async (folders, on) => {
  for (const f of folders) {
    if (!f) continue;
    const r = await exec("test", ["-d", f], { on }).catch(() => null);
    if (r?.code === 0) return f;
  }
  return null;
};
