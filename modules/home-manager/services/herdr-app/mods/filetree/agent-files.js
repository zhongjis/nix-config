// Ported from ChmaraX/herdr-nvim src/sessions.rs and src/app/session.rs (MIT,
// Copyright (c) 2026 Adam Chmara). See LICENSE-herdr-nvim.
// Pure mining and injected exec IO: this module also runs directly under Node.
/**
 * @typedef {"pi" | "claude"} AgentKind
 * @typedef {"read" | "write" | "edit"} Op
 * @typedef {{path: string, op: Op, at: number | null}} RawEvent
 * @typedef {{abs: string, kind: string, at: number, newlyCreated: boolean, wasEdited: boolean, sequence: number}} Touch
 * @typedef {{kind: AgentKind, cwd: string, since: number, on?: string | null}} Source
 * @typedef {(command: string, args: string[], options?: {on?: string | null}) => Promise<{code: number, stdout: string, stderr?: string}>} Exec
 */
/** @param {...(string | null | undefined)} names @returns {AgentKind | null} */
export function agentKind(...names) {
  for (const raw of names) {
    const name = String(raw ?? "").toLowerCase();
    if (name.includes("claude")) return "claude";
    if (name === "pi" || name.startsWith("pi-") || name.startsWith("pi ")) return "pi";
  }
  return null;
}

/** @param {string} cwd */
export const piSlug = (cwd) => `--${cwd.replace(/^\//, "").replace(/[\\/:]/g, "-")}--`;
/** @param {string} cwd */
export const claudeSlugs = (cwd) => [cwd.replace(/\//g, "-"), cwd.replace(/[^a-zA-Z0-9]/gu, "-")];
/** @param {string} text */
export function parseEtime(text) {
  const match = /^(?:(\d+)-)?(\d+(?::\d+){1,2})$/.exec(text.trim());
  return match ? (Number(match[1] ?? 0) * 86400 + match[2].split(":").reduce((n, p) => n * 60 + Number(p), 0)) * 1000 : null;
}
/** @param {{path: string, mtime: number}[]} files @param {number} since */
export function newestSince(files, since) {
  return files.filter((f) => f.mtime >= since - 2000).sort((a, b) => b.mtime - a.mtime)[0]?.path ?? null;
}

/** @type {Record<AgentKind, Record<string, Op>>} */
const TOOLS = {
  pi: { read: "read", write: "write", edit: "edit" },
  claude: { Read: "read", Write: "write", Edit: "edit", MultiEdit: "edit", NotebookEdit: "edit" },
};
/** @param {unknown} value @returns {Record<string, unknown>} */
function record(value) { return value && typeof value === "object" && !Array.isArray(value) ? Object.fromEntries(Object.entries(value)) : {}; }

// A malformed/incomplete log record must never break the Recent view.
/** @param {string} line @param {AgentKind} kind @returns {RawEvent[]} */
export function parseLine(line, kind) {
  /** @type {unknown} */
  let parsedValue;
  try { parsedValue = JSON.parse(line); }
  catch (error) { if (error instanceof SyntaxError) return []; throw error; }
  const value = record(parsedValue);
  if (kind === "pi" && value.type !== "message") return [];
  const content = record(value.message).content;
  if (!Array.isArray(content)) return [];
  const timestamp = value.timestamp ?? value.created_at;
  const parsed = typeof timestamp === "string" && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z$/.test(timestamp) ? Date.parse(timestamp) : NaN;
  const at = Number.isFinite(parsed) ? parsed : null;
  return content.flatMap((raw) => {
    const item = record(raw);
    if (item.type !== (kind === "pi" ? "toolCall" : "tool_use") || typeof item.name !== "string") return [];
    const op = Object.hasOwn(TOOLS[kind] ?? {}, item.name) ? TOOLS[kind][item.name] : null;
    if (!op) return [];
    const args = record(kind === "pi" ? item.arguments : item.input);
    const paths = kind === "pi" ? [args.path, args.file_path] : [args.file_path, args.path];
    const path = paths.find((p) => typeof p === "string");
    return path === undefined ? [] : [{ path: kind === "pi" ? path.replace(/^@/, "") : path, op, at }];
  });
}

/** @param {string} cwd @param {string} path */
export function resolvePath(cwd, path) {
  const absolute = path.startsWith("/") ? path : `${cwd}/${path}`;
  const parts = [];
  for (const part of absolute.split("/")) {
    if (part === "..") parts.pop();
    else if (part && part !== ".") parts.push(part);
  }
  return "/" + parts.join("/");
}

// Scan in file order: first op determines 'new', every op updates last touch.
// The accumulator is retained across appended chunks, not rebuilt on every poll.
export class SessionFiles {
  /** @param {{kind: AgentKind, cwd: string, since?: number}} source */
  constructor({ kind, cwd, since = 0 }) {
    this.kind = kind; this.cwd = cwd; this.since = since;
    /** @type {Map<string, Touch>} */
    this.touches = new Map(); this.offset = 0; this.sequence = 0;
  }
  /** @param {string} text */
  append(text) {
    const end = text.lastIndexOf("\n") + 1;
    const complete = text.slice(0, end), fresh = [];
    // Count UTF-8 bytes, not JS UTF-16 code units; the native runtime has no Node Buffer.
    for (const char of complete) {
      const point = char.codePointAt(0);
      this.offset += point < 128 ? 1 : point < 2048 ? 2 : point < 65536 ? 3 : 4;
    }
    for (const line of complete.split("\n")) for (const event of parseLine(line, this.kind)) {
      if (event.at !== null && event.at < this.since - 2000) continue;
      const abs = resolvePath(this.cwd, event.path), previous = this.touches.get(abs);
      const touch = { abs, kind: event.op === "read" ? "read" : "write", at: event.at ?? previous?.at ?? this.since,
        newlyCreated: previous?.newlyCreated ?? event.op === "write", wasEdited: Boolean(previous?.wasEdited || event.op !== "read"), sequence: ++this.sequence };
      this.touches.set(abs, touch); fresh.push(touch);
    }
    return fresh;
  }
  history() { return [...this.touches.values()].sort((a, b) => a.at - b.at || a.sequence - b.sequence); }
}

// readTextFile is capped at 1 MiB and has no ranged read. tail starts at our byte
// offset, head bounds each batch by records. An unfinished final line is reread.
/** @param {Exec} exec @param {{path: string, on?: string | null}} source @param {SessionFiles} miner */
export async function readSession(exec, source, miner) {
  const result = await exec("sh", ["-c", 'tail -c +"$1" "$2" 2>/dev/null | head -n 200', "filetree", String(miner.offset + 1), source.path], { on: source.on });
  return result.code === 0 ? miner.append(result.stdout) : [];
}

/** @param {Exec} exec @param {Source} source */
export async function discoverSession(exec, source) {
  const { kind, cwd, since, on } = source;
  // Respect the agent config roots and canonical cwd, as upstream does.
  const roots = await exec("sh", ["-c", 'printf "%s\\n%s\\n%s\\n" "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" "$(cd "$1" 2>/dev/null && pwd -P)"', "filetree", cwd], { on });
  if (roots.code !== 0) return null;
  const [pi, claude, real] = roots.stdout.trimEnd().split("\n");
  const dirs = [...new Set([cwd, real].filter(Boolean).flatMap((c) => kind === "pi" ? [`${pi}/${piSlug(c)}`] : claudeSlugs(c).map((slug) => `${claude}/${slug}`)))];
  const result = await exec("sh", ["-c", 'for d do (set -- "$d"/*.jsonl; [ -f "$1" ] || exit 0; if stat -c %Y "$1" >/dev/null 2>&1; then stat -c \'%Y\t%n\' -- "$@"; else stat -f \'%m\t%N\' -- "$@"; fi); done', "filetree", ...dirs], { on });
  const files = result.stdout.trim().split("\n").flatMap((line) => {
    const tab = line.indexOf("\t");
    return tab < 0 ? [] : [{ mtime: Number(line.slice(0, tab)) * 1000, path: line.slice(tab + 1) }];
  });
  return newestSince(files, since);
}
