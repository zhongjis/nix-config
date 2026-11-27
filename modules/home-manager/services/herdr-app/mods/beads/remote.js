// The ticket a bead mirrors, as its tracker says now: state and last update. Read-only.
// Linear: GraphQL `issue(id: KEY)` at https://api.linear.app with LINEAR_API_KEY.
// Jira: GET <jira.url>/rest/api/2/issue/<KEY>?fields=status,updated with JIRA_TOKEN as a Bearer token, only over HTTPS and
// only for a ref on the origin bd's `jira.url` names (the one place that says which Jira the person trusts). The request
// is built from that configured base, never from the ref. A token never follows a redirect to another origin: the
// app's fetch refuses a cross-origin redirect of a request that carries Authorization (verified on the installed
// runtime with a credential-free local probe: it rejects "cross-origin redirect … refused because the request
// carries Authorization" and the second origin is never contacted). fetch takes only method, headers and body; any
// other option (such as `redirect`) makes it throw. An answer whose final URL left the origin is refused too.
// Tokens come from the login shell (the app's own environment may lack them), are held in memory only, dropped when the
// tracker refuses them, and never logged, shown or put in an error.
// An answer is kept 5 minutes per ticket; a failure 1 minute, so a fixed token or a network blip recovers on its own.
//
// Imports nothing from "herdr" (node tests load it); main.js hands in what it needs:
//   new Remote({ token(name) -> Promise<string>, jiraUrl() -> Promise<string>, fetch, now? })
import { remoteRef } from "./layout.js";

const TTL = 5 * 60 * 1000, ERROR_TTL = 60 * 1000, STUCK = 30 * 1000;
const VARIABLES = { linear: "LINEAR_API_KEY", jira: "JIRA_TOKEN" };
const LINEAR_URL = "https://api.linear.app/graphql";
const LINEAR_QUERY = "query($key: String!) { issue(id: $key) { state { name type color } updatedAt url } }";
const PLAIN_JIRA = "This Jira isn't the one bd is configured for (jira.url), so its state isn't read.";

// How a tracker's state reads in the view: to do, started, finished, dropped.
const LINEAR_KIND = { backlog: "todo", unstarted: "todo", triage: "todo", started: "active", completed: "done", canceled: "canceled" };
const JIRA_KIND = { new: "todo", indeterminate: "active", done: "done" };

class Refused extends Error {}

const time = (iso) => { const at = Date.parse(iso ?? ""); return Number.isNaN(at) ? null : at; };
const host = (url) => /^https?:\/\/([^/]+)/.exec(url)?.[1] ?? "the tracker";

/** An https URL as { origin, base } (base: origin plus its path, no trailing slash), else null. @param {unknown} raw */
export function httpsBase(raw) {
  try {
    const u = new URL(String(raw ?? "").trim());
    if (u.protocol !== "https:" || u.username || u.password) return null;
    return { origin: u.origin, base: u.origin + u.pathname.replace(/\/+$/, "") };
  } catch {
    return null;
  }
}

export class Remote {
  /** @param {{ token: (name: string) => Promise<string>, jiraUrl: () => Promise<string>, fetch: typeof fetch, now?: () => number }} deps */
  constructor(deps) {
    this.deps = deps;
    this.cache = new Map();
    this.tokens = new Map();
    this.jira = null;
  }

  now() { return this.deps.now ? this.deps.now() : Date.now(); }

  // The cache key: provider, the origin asked, the ticket.
  idOf(r) {
    if (!r?.provider || !r.key) return null;
    if (r.provider === "linear") return `linear:${new URL(LINEAR_URL).origin}:${r.key}`;
    try { return `jira:${new URL(r.base).origin}:${r.key}`; } catch { return null; }
  }

  // What is known about a bead's ticket, without asking: { kind: "none", note? } | the cache entry | null (not asked yet).
  peek(ref) {
    const r = remoteRef(ref);
    const id = this.idOf(r);
    if (!id) return { kind: "none", ref: r };
    const e = this.cache.get(id);
    if (e?.status === "plain") return { kind: "none", ref: r, note: e.message };
    // A refresh under way keeps showing the last answer.
    return e?.status ? { kind: "known", ref: r, ...e } : { kind: e ? "loading" : "idle", ref: r };
  }

  async token(provider) {
    const name = VARIABLES[provider];
    if (this.tokens.has(name)) return this.tokens.get(name);
    const token = String(await this.deps.token(name) ?? "").trim();
    if (token) this.tokens.set(name, token);
    return token;
  }

  // The configured Jira, asked at most every 5 minutes: { origin, base } | null (unset, or not https).
  async jiraBase() {
    if (this.jira && this.now() - this.jira.at < TTL) return this.jira.value;
    let value = null;
    try { value = httpsBase(await this.deps.jiraUrl()); } catch { return null; }
    this.jira = { at: this.now(), value };
    return value;
  }

  // Starts a fetch when the entry is missing or expired; redraws through `cx` when it lands.
  ensure(ref, cx) {
    const r = remoteRef(ref);
    const id = this.idOf(r);
    if (!id) return;
    const now = this.now(), e = this.cache.get(id);
    if (e?.pending ? now - e.pending < STUCK : e && now - e.at < (e.status === "ok" || e.status === "plain" ? TTL : ERROR_TTL)) return;
    this.cache.set(id, { ...e, pending: now });
    cx.spawn(async (cx) => {
      this.cache.set(id, await this.entry(r));
      cx.notify();
    });
  }

  // The cache entry for one ticket: asks the tracker; every failure is an entry, never a throw.
  async entry(r) {
    try {
      return { at: this.now(), status: "ok", value: await this.read(r) };
    } catch (err) {
      const at = this.now();
      if (err instanceof Refused && err.plain) return { at, status: "plain", message: err.message };
      if (err instanceof Refused && err.variable) return { at, status: "no-token", variable: err.variable };
      return { at, status: "error", message: err instanceof Refused ? err.message : "The ticket could not be read." };
    }
  }

  // One request. `origin` is the only place the answer may come from. A refused token is forgotten, so the next
  // attempt reads the login shell again.
  async send(provider, origin, url, options) {
    let res;
    try {
      res = await this.deps.fetch(url, options);
    } catch {
      throw new Refused(`Couldn't reach ${host(url)}.`);
    }
    if (res.url && httpsBase(res.url)?.origin !== origin) throw new Refused(`${host(url)} answered from another address.`);
    if (res.status === 401 || res.status === 403) {
      this.tokens.delete(VARIABLES[provider]);
      throw new Refused(`${host(url)} refused the token (HTTP ${res.status}).`);
    }
    if (res.status === 404) throw new Refused("The tracker doesn't know this ticket (HTTP 404).");
    if (!res.ok) throw new Refused(`${host(url)} answered HTTP ${res.status}.`);
    try {
      return await res.json();
    } catch {
      throw new Refused(`${host(url)} sent an answer that isn't JSON.`);
    }
  }

  async read(r) {
    const variable = VARIABLES[r.provider];
    let jira = null;
    if (r.provider === "jira") {
      jira = await this.jiraBase();
      if (!jira || jira.origin !== httpsBase(r.base)?.origin) throw Object.assign(new Refused(PLAIN_JIRA), { plain: true });
    }
    const token = await this.token(r.provider);
    if (!token) throw Object.assign(new Refused("No token."), { variable });
    if (r.provider === "linear") {
      const data = await this.send("linear", new URL(LINEAR_URL).origin, LINEAR_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json", Authorization: token },
        body: JSON.stringify({ query: LINEAR_QUERY, variables: { key: r.key } }),
      });
      const failure = data?.errors?.[0];
      if (failure) {
        // Linear says a key is bad with HTTP 200 and an authentication error: forget it, as a 401 would.
        const auth = failure.extensions?.code === "AUTHENTICATION_ERROR" || /authenticat|api key|unauthori[sz]ed/i.test(String(failure.message ?? ""));
        if (auth) this.tokens.delete(VARIABLES.linear);
        throw new Refused(`Linear: ${String(failure.message ?? "the request failed").slice(0, 120)}`);
      }
      const issue = data?.data?.issue;
      if (!issue) throw new Refused("The tracker doesn't know this ticket.");
      const kind = LINEAR_KIND[issue.state?.type] ?? "todo";
      return { state: issue.state?.name ?? "Unknown", kind, color: issue.state?.color ?? null, updatedAt: time(issue.updatedAt), url: issue.url ?? r.url };
    }
    const data = await this.send("jira", jira.origin, `${jira.base}/rest/api/2/issue/${encodeURIComponent(r.key)}?fields=status,updated`, {
      headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
    });
    const status = data?.fields?.status;
    if (!status) throw new Refused("The tracker doesn't know this ticket.");
    return { state: status.name ?? "Unknown", kind: JIRA_KIND[status.statusCategory?.key] ?? "todo", color: null, updatedAt: time(data.fields.updated), url: `${jira.base}/browse/${r.key}` };
  }
}
