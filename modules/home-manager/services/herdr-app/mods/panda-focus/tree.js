// An agent with the sub-agents it started, one reading for Focus cards, the agents list, tabs and pane headers:
// stuck itself needs the person; an agent waiting on sub-agents, working or stuck, is still at work, even with an
// unread reply (they report to it, so the next move isn't the person's); else its own word. A stuck sub-agent
// with a pane asks on its own card.
// A copy lives in each mod that uses it (scripts/sync.sh), as name.js does.

// A sub-agent's own word: a sub-agent without a pane isn't in agents(), so its raw word, error counting as
// blocked. It's never done: it reports to its parent, and the parent's done is the news.
export const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};

// Live sub-agents of `addr`, all the way down.
export function descendants(all, addr) {
  return all.filter((k) => k.parent === addr && k.state === "live").flatMap((k) => [k, ...descendants(all, k.address)]);
}

// Its own word with what's under it: needing the person first, then busy or waiting on sub-agents it will hear
// back from, else its own. No word of its own: no agent, whatever it started.
export function treeStatus(own, kids) {
  if (own == null) return own;
  if (own === "blocked") return "blocked";
  return kids.some((s) => s === "working" || s === "blocked") ? "working" : own;
}

// Snapshot once per render, like namer(): what's under each address, as words.
export function subAgents(agentList, all) {
  const listed = new Map(agentList.map((a) => [a.address, a.status]));
  return (addr) => descendants(all, addr).map((k) => kidStatus(k, listed));
}
