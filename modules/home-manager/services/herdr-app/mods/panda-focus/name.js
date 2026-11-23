// What a terminal is on, one rule for Focus cards, the agents list, tabs and pane headers:
// its pane's name, then (agents only) a tab someone named, then a telling terminal title, else the program.
// A terminal with no title of its own reports its address (t9) as one: that tells nothing.
import { spaces, panes } from "herdr";

const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

// Snapshot once per render; the returned function takes an agent or a pane (status set = an agent).
export function namer() {
  const tabs = new Map(spaces().flatMap((s) => s.tabs.map((c) => [c.id, c])));
  const paneName = new Map(panes().filter((p) => p.terminal).map((p) => [p.terminal, p.name]));
  return (x) => {
    const address = x.address ?? x.terminal;
    // A pane's name (pane.rename) wins: a person's always, Pi's "[w] …" only while Pi runs, so one a killed Pi left
    // doesn't sit over a shell. agents() carry pane_name; a terminals() entry's name is hc's own (w-…), so go by address.
    const named = x.pane_name ?? paneName.get(address);
    if (named && (!named.startsWith("[w] ") || x.program?.key === "pi")) return named;
    const tab = tabs.get(x.tab);
    const live = clean(x.title);
    const telling = live && live !== x.program?.name && live.toLowerCase() !== x.program?.key
      && !/^[~/]|^[A-Za-z]:\\/.test(live) && !live.includes("@") && live !== address;
    return (x.status != null && tab?.named && tab.name)
      || (telling && live) || x.program?.name || address || "shell";
  };
}
