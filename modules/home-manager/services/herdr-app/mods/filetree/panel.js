// Adapted from ChmaraX/herdr-nvim (MIT; LICENSE-herdr-nvim).
// The side panel that holds filetree, as `layout()` describes it, and
// the commands the tab bar's Files button runs on it (mods/tabs/main.js).

import { panes, run, terminals } from "herdr";

// The nodes from the root to the tree's block (the `files` slot), or null.
function slotPath(node, trail = []) {
  if (!node) return null;
  const here = [...trail, node];
  if (node.content?.mod === "filetree" && node.content?.props?.panel && node.content?.props?.role !== "sync") return here;
  for (const child of node.children ?? []) {
    const found = slotPath(child, here);
    if (found) return found;
  }
  return null;
}

// { stack, slot, panel, files, other }: `files` while the panel shows the
// tree, `other` while it shows another child of the stack (Changes). Null in
// a layout without filetree's slot.
export function panelState(root) {
  const path = slotPath(root);
  if (!path) return null;
  const at = path.findLastIndex((node) => node.type === "stack");
  const stack = path[at], slot = path[path.length - 1];
  const panel = at > 0 ? path[at - 1] : slot;
  // Shown: every node down to the stack, and the slot itself (a layout
  // without a stack hides the slot).
  const shown = path.slice(0, Math.max(at, 0) + 1).every((node) => !node.hidden) && !slot.hidden;
  return {
    stack: stack?.id ?? null,
    slot: slot.id,
    panel: panel.id,
    files: shown && (!stack || stack.active === slot.id),
    other: shown && Boolean(stack) && stack.active !== slot.id,
  };
}

export function showFiles(p) {
  if (p.stack) run("layout.select", { stack: p.stack, child: p.slot });
  run("layout.show", { id: p.panel });
}

export function hidePanel(p) {
  run("layout.hide", { id: p.panel });
}

// The tab's live filetree nvim terminals (nvim's screen in its pane).
function nvimTerminals(tab) {
  return terminals().filter((t) => t.state === "live" && t.labels?.["filetree.nvim"] === tab).map((t) => t.address);
}

// The ones a pane of the tab shows: the tab's nvim pane.
export function nvimPanes(tab) {
  const shown = new Set(panes().map((p) => p.terminal));
  return nvimTerminals(tab).filter((t) => shown.has(t));
}

// The tab's parked nvim: running, in no pane (`terminal.park`, sync.js),
// so the next Files shows it again as it was, with no process to start.
export function parkedNvim(tab) {
  const shown = new Set(panes().map((p) => p.terminal));
  return nvimTerminals(tab).find((t) => !shown.has(t)) ?? null;
}

// The tab's own panes: not nvim's, not a preview (its agents and shells).
export function ownPanes(tab) {
  const nvims = new Set(nvimTerminals(tab));
  return panes().filter((p) => p.tab === tab && !nvims.has(p.terminal));
}

// Whether the app lists a terminal as ended.
export function ended(address) {
  return terminals().some((t) => t.address === address && t.state !== "live");
}

// Make the tree the app's focused block, the one way the app has: `pane.go`
// right from the tab's nvim pane (the full-height pane next to the panel).
// Only then does the app (0.1.12) move its focus ring off the pane before.
// Always from nvim's pane: `focused()` names a pane even while a block (the
// tree itself) holds the keyboard, and `pane.go` starts from that block.
export function goToTree(terminal) {
  run("pane.focus", { terminal });
  run("pane.go", { direction: "right" });
}
