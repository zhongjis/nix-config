// Pure git/gh response reduction; no app state.
export function githubRepo(remote) {
  const match = /^(?:git@([^:/\s]+):|https?:\/\/([^/\s]+)\/|ssh:\/\/git@([^/\s]+)\/)([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(remote.trim());
  if (!match) return null;
  const host = (match[1] ?? match[2] ?? match[3]).toLowerCase().replace(/^github\.com-.+$/, "github.com");
  return `${host === "github.com" ? "" : host + "/"}${match[4]}/${match[5]}`;
}

// Checkouts in the system's temp folders are scratch copies (an agent's), not work to list.
const TEMP = /^(\/tmp|\/var\/tmp|\/var\/folders|\/private\/var\/folders)\//;

export function checkouts(porcelain) {
  return porcelain.split(/\n\n+/).flatMap(block => {
    const lines = block.split("\n");
    const folder = lines.find(l => l.startsWith("worktree "))?.slice(9);
    // Detached checkouts have no branch to go by or PR to show.
    if (!folder || TEMP.test(folder) || lines.some(l => l === "bare" || l === "detached" || l.startsWith("prunable"))) return [];
    const branch = lines.find(l => l.startsWith("branch "))?.slice(7).replace(/^refs\/heads\//, "") ?? null;
    return [{ folder, branch }];
  });
}

export function ciRollup(checks) {
  if (!checks?.length) return null;
  const states = checks.map(c => {
    if (c.__typename === "StatusContext" || c.state) return ["FAILURE", "ERROR"].includes(c.state) ? "fail" : c.state === "SUCCESS" ? "pass" : "pending";
    if (c.status !== "COMPLETED") return "pending";
    return ["FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(c.conclusion) ? "fail" : "pass";
  });
  return states.includes("fail") ? "fail" : states.includes("pending") ? "pending" : "pass";
}
