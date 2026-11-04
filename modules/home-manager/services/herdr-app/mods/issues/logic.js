// Provider payloads become the same small issue model used by the popup.
export const DEFAULT_JQL = "assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC";
export const defaults = {
  jira: { url: "", jql: DEFAULT_JQL, tokenCommand: "printenv JIRA_TOKEN" },
  linear: { enabled: false, tokenCommand: "printenv LINEAR_API_KEY" },
};

export function tokenOutput(output) {
  const token = output.trim();
  if (!token) throw new Error("Token command returned no token.");
  if (/[\r\n]/.test(token)) throw new Error("Token command must return exactly one line.");
  return token;
}

// A Jira status in Linear's terms: its category says how far along it is.
export function jiraState(status) {
  const name = status?.name ?? "Unknown";
  const category = status?.statusCategory?.key;
  const type = category === "indeterminate" ? "started"
    : category === "done" ? (/cancel|reject|declin|won.?t|duplicate/i.test(name) ? "canceled" : "completed")
    : /backlog/i.test(name) ? "backlog" : "unstarted";
  return { id: status?.id, name, type, color: "" };
}

// A priority as Linear's level: 1 urgent … 4 low, 0 none.
export function priorityLevel(name) {
  const n = (name ?? "").toLowerCase();
  if (/blocker|highest|urgent/.test(n)) return 1;
  if (/critical|high/.test(n)) return 2;
  if (/major|medium|normal/.test(n)) return 3;
  if (/minor|low|trivial/.test(n)) return 4;
  return 0;
}

export function jiraIssue(raw, host) {
  const f = raw.fields;
  return {
    id: raw.id, identifier: raw.key, title: f.summary, description: f.description ?? "",
    state: jiraState(f.status), type: f.issuetype?.name ?? "",
    assignee: f.assignee?.displayName ?? "", project: f.project?.name ?? "",
    priority: f.priority?.name ?? "", level: priorityLevel(f.priority?.name), labels: f.labels ?? [], updated: f.updated,
    url: `${host}/browse/${encodeURIComponent(raw.key)}`,
    links: (f.issuelinks ?? []).flatMap((l) => {
      const issue = l.outwardIssue ?? l.inwardIssue;
      return issue ? [{ title: `${issue.key} ${issue.fields?.summary ?? ""}`, url: `${host}/browse/${encodeURIComponent(issue.key)}` }] : [];
    }),
  };
}

export function linearIssue(raw) {
  return {
    id: raw.id, identifier: raw.identifier, title: raw.title, description: raw.description ?? "",
    state: raw.state, type: "", assignee: raw.assignee?.displayName ?? "", project: raw.project?.name ?? "",
    priority: raw.priorityLabel ?? "", level: raw.priority ?? 0, labels: (raw.labels?.nodes ?? []).map((l) => l.name),
    updated: raw.updatedAt, url: raw.url,
    links: (raw.attachments?.nodes ?? []).map((l) => ({ title: l.title, url: l.url })),
  };
}

// Issues grouped by status, in the order work moves: started (review
// first), to do, triage, backlog, done, canceled; else as listed.
const ORDER = ["started", "unstarted", "triage", "backlog", "completed", "canceled"];
const rank = (s) => {
  const i = ORDER.indexOf(s.type);
  return (i < 0 ? ORDER.length : i) * 2 - (s.type === "started" && /review/i.test(s.name) ? 1 : 0);
};
export function byStatus(issues) {
  const groups = new Map();
  for (const issue of issues) {
    const group = groups.get(issue.state.name) ?? { name: issue.state.name, state: issue.state, issues: [] };
    group.issues.push(issue);
    groups.set(group.name, group);
  }
  return [...groups.values()].sort((a, b) => rank(a.state) - rank(b.state));
}

// Every word of the filter is somewhere in the issue.
export function matches(issue, filter) {
  const hay = [issue.identifier, issue.title, issue.state?.name, issue.project, issue.type, issue.assignee].filter(Boolean).join(" ").toLowerCase();
  return filter.toLowerCase().split(/\s+/).filter(Boolean).every((w) => hay.includes(w));
}

// What a failed request says: Jira's or Linear's own messages, else the
// start of the body on one line.
export function httpReason(status, body) {
  let parts = [];
  try {
    const json = JSON.parse(body);
    parts = [json.message, ...(json.errorMessages ?? []), ...(Array.isArray(json.errors) ? json.errors.map((e) => e.message) : Object.values(json.errors ?? {}))];
  } catch {
    // Not JSON: an HTML error page or plain text.
  }
  const reason = parts.filter(Boolean).join(" ") || body.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim().slice(0, 240);
  return `HTTP ${status}${reason ? `: ${reason}` : ""}`;
}

export function projectKeys(jql, issues) {
  const keys = issues.map((i) => i.identifier.replace(/-\d+$/, ""));
  for (const match of jql.matchAll(/\bproject\s+in\s*\(([^)]+)\)/gi)) {
    for (const part of match[1].split(",")) {
      const key = part.trim().replace(/^["']|["']$/g, "");
      if (/^[A-Za-z][A-Za-z0-9_]*$/.test(key)) keys.push(key.toUpperCase());
    }
  }
  return [...new Set(keys)];
}

// Jira wiki markup as Markdown, for its common parts: headings, bold,
// monospace, code blocks, links, mentions, lists, tables and line breaks.
const inline = (s) => s
  .replace(/\{\{(.+?)\}\}/g, "`$1`")
  .replace(/\[~([^\]]+)\]/g, "@$1")
  .replace(/\[([^|\]\n]+)\|([^\]\s]+)\]/g, "[$1]($2)")
  .replace(/\[(https?:\/\/[^\]\s]+)\]/g, "<$1>")
  .replace(/(^|[\s(])\*(\S(?:[^*\n]*\S)?)\*(?=[\s).,:;!?]|$)/g, "$1**$2**")
  .replace(/\{color(?::[^}]*)?\}/g, "");
const cells = (row, sep) => row.trim().split(sep).slice(1, -1).map((c) => inline(c.trim()));
function line(text) {
  const heading = /^h([1-6])\.\s*(.*)$/.exec(text);
  if (heading) return `${"#".repeat(Number(heading[1]))} ${inline(heading[2])}`;
  const item = /^\s*([*#-]+)\s+(.*)$/.exec(text);
  if (item) return `${"  ".repeat(item[1].length - 1)}${item[1].endsWith("#") ? "1." : "-"} ${inline(item[2])}`;
  if (/^\s*\|\|/.test(text)) {
    const head = cells(text, "||");
    return `| ${head.join(" | ")} |\n|${head.map(() => " --- |").join("")}`;
  }
  if (/^\s*\|/.test(text)) return `| ${cells(text, "|").join(" | ")} |`;
  return text.trim() ? `${inline(text)}  ` : "";
}
export function jiraMarkdown(text) {
  return text.replace(/\r\n?/g, "\n").split(/\{(?:code|noformat)(?::[^}]*)?\}([\s\S]*?)\{(?:code|noformat)\}/)
    .map((part, i) => (i % 2 ? `\n\`\`\`\n${part.replace(/^\n+|\n+$/g, "")}\n\`\`\`\n` : part.split("\n").map(line).join("\n")))
    .join("");
}

export const KEY = /^[A-Za-z][A-Za-z0-9_]*-\d+$/;
export function issueKey(key) {
  const value = key.trim().toUpperCase();
  if (!KEY.test(value)) throw new Error("Enter an issue key, for example TEAM-123.");
  return value;
}
