// The controller's rule (sync.js, top of the file), as a pure function, so
// it can be checked outside the app (herdr-app/e2e/js-checks.mjs).

// Pure: what the last change on the shown tab asks for, applying the rule
// at the top. `cur`/`prev`: {tab, files, other, nvim} now and at the last
// look. Returns `panel` ("show": the panel follows the tab's nvim) and
// `nvim` (true: the tab's nvim follows the panel closing, `act`).
// Adapted: the tree stands alone. Opening it starts no nvim (a file opened
// from it does), and a tab without nvim keeps its panel.
export function wanted(cur, prev) {
  const followTab = () => (cur.nvim && !cur.files && !cur.other ? "show" : null);
  // The panel opened: nvim waits for a file.
  if (prev && !prev.files && cur.files) return {};
  if (!prev || prev.tab !== cur.tab) return { panel: followTab() };
  // The panel closed (not to Changes): a shown nvim is parked with it.
  if (prev.files !== cur.files) return { nvim: !cur.other && cur.nvim };
  // nvim appeared (a file opened): the panel shows with it. nvim went: the panel stays.
  if (!prev.nvim && cur.nvim) return { panel: followTab() };
  return {};
}
