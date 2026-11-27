// Beads view remote state (mods/beads/remote.js): where a tracker token may go, token refresh, Linear errors.
// remote.js imports nothing from "herdr"; the token reader, bd's jira.url and fetch are stubs. Made-up hosts only.
// Run: node modules/home-manager/services/herdr-app/tests/beads-remote.mjs
import assert from "node:assert/strict";
import { Remote } from "../mods/beads/remote.js";
import { remoteRef } from "../mods/beads/layout.js";

const JIRA_REF = "https://tracker.example/browse/ABC-12";
const LINEAR_REF = "https://linear.app/example-org/issue/ABC-12/some-title";

/** A Remote over stubs. `answer(url, options)` returns { status, body, url? }; `tokens` are handed out in order. */
function setup({ jira = "https://tracker.example", tokens = ["secret-1"], answer }) {
  const calls = [], reads = [];
  let clock = 1_000_000;
  const remote = new Remote({
    token: async (name) => { reads.push(name); return tokens[Math.min(reads.length - 1, tokens.length - 1)]; },
    jiraUrl: async () => jira,
    fetch: async (url, options) => {
      calls.push({ url, options });
      const a = answer(url, options);
      return { ok: a.status >= 200 && a.status < 300, status: a.status, url: a.url ?? url, json: async () => a.body };
    },
    now: () => clock,
  });
  return { remote, calls, reads, tick: (ms) => { clock += ms; } };
}
const ok = (body) => ({ status: 200, body });
const jiraIssue = { fields: { status: { name: "In Progress", statusCategory: { key: "indeterminate" } }, updated: "2026-01-01T00:00:00Z" } };

// Jira on the configured https origin: one request, built from the configured base, token as a Bearer
{
  const { remote, calls } = setup({ answer: () => ok(jiraIssue) });
  const e = await remote.entry(remoteRef(JIRA_REF));
  assert.equal(e.status, "ok");
  assert.equal(e.value.state, "In Progress");
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://tracker.example/rest/api/2/issue/ABC-12?fields=status,updated");
  assert.equal(calls[0].options.headers.Authorization, "Bearer secret-1");
  // The app's fetch takes method, headers and body only; any other option throws (verified on the installed runtime).
  assert.deepEqual(Object.keys(calls[0].options).filter((k) => !["method", "headers", "body"].includes(k)), []);
}

// The request URL comes from the configured base, context path included, never from the ref
{
  const { remote, calls } = setup({ jira: "https://tracker.example/jira/", answer: () => ok(jiraIssue) });
  await remote.entry({ provider: "jira", key: "ABC-12", base: "https://tracker.example/other", url: "https://tracker.example/other/browse/ABC-12" });
  assert.equal(calls[0].url, "https://tracker.example/jira/rest/api/2/issue/ABC-12?fields=status,updated");
}

// A Jira ref on another host, on http, or with no configured jira.url: no token read, no request, a plain link
const plain = [
  ["another host", "https://evil.example/browse/ABC-12", {}],
  ["http ref", "http://tracker.example/browse/ABC-12", {}],
  ["http config", JIRA_REF, { jira: "http://tracker.example" }],
  ["no jira.url", JIRA_REF, { jira: "" }],
  ["port differs", "https://tracker.example:8443/browse/ABC-12", {}],
];
for (const [label, ref, opts] of plain) {
  const { remote, calls, reads } = setup({ ...opts, answer: () => ok(jiraIssue) });
  const cx = { spawn: (f) => f({ notify() {} }) };
  remote.ensure(ref, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(calls.length, 0, label);
  assert.equal(reads.length, 0, `${label}: token untouched`);
  const info = remote.peek(ref);
  assert.equal(info.kind, "none", label);
  assert.ok(info.note, label);
}

// A cross-origin redirect with Authorization is refused by the app's fetch itself (verified live); a final URL off the
// origin is refused here too
{
  const { remote } = setup({ answer: () => ok(jiraIssue) });
  const r = remoteRef(JIRA_REF);
  const moved = setup({ answer: () => ({ status: 200, body: jiraIssue, url: "https://elsewhere.example/rest/api/2/issue/ABC-12" }) });
  const e = await moved.remote.entry(r);
  assert.equal(e.status, "error");
  assert.ok(!JSON.stringify(e).includes("secret-1"));
  assert.equal((await remote.entry(r)).status, "ok");
}

// Cache key: provider, origin and ticket
{
  const { remote } = setup({ answer: () => ok(jiraIssue) });
  const cx = { spawn: (f) => f({ notify() {} }) };
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(remote.peek(JIRA_REF).status, "ok");
  assert.ok([...remote.cache.keys()].every((k) => k.startsWith("jira:https://tracker.example:ABC-12")), [...remote.cache.keys()].join());
  assert.equal(remote.peek("https://other.example/browse/ABC-12").kind, "idle");
}

// A rejected token is forgotten: the next ensure reads the login shell again and succeeds
{
  const { remote, reads, calls, tick } = setup({
    tokens: ["stale", "fresh"],
    answer: (_u, o) => (o.headers.Authorization === "Bearer stale" ? { status: 401, body: {} } : ok(jiraIssue)),
  });
  const cx = { spawn: (f) => f({ notify() {} }) };
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(remote.peek(JIRA_REF).status, "error");
  assert.match(remote.peek(JIRA_REF).message, /refused the token/);
  assert.ok(!remote.peek(JIRA_REF).message.includes("stale"));
  assert.equal(reads.length, 1);
  tick(61_000);
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(reads.length, 2, "the token was read again");
  assert.equal(remote.peek(JIRA_REF).status, "ok");
  assert.equal(calls.at(-1).options.headers.Authorization, "Bearer fresh");
}

// A good token is kept: a refresh after the TTL does not ask the shell again
{
  const { remote, reads, tick } = setup({ answer: () => ok(jiraIssue) });
  const cx = { spawn: (f) => f({ notify() {} }) };
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  tick(6 * 60_000);
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(reads.length, 1);
}

// No token: the variable to set, no request
{
  const { remote, calls } = setup({ tokens: [""], answer: () => ok(jiraIssue) });
  const cx = { spawn: (f) => f({ notify() {} }) };
  remote.ensure(JIRA_REF, cx);
  await new Promise((r) => setImmediate(r));
  assert.equal(remote.peek(JIRA_REF).status, "no-token");
  assert.equal(remote.peek(JIRA_REF).variable, "JIRA_TOKEN");
  assert.equal(calls.length, 0);
}

// Linear: its GraphQL errors arrive as HTTP 200 and are errors, not "unknown ticket"; the token is never in the message
{
  const { remote, calls } = setup({
    tokens: ["lin_api_secret"],
    answer: () => ok({ errors: [{ message: "Authentication required, not authenticated" }] }),
  });
  const e = await remote.entry(remoteRef(LINEAR_REF));
  assert.equal(e.status, "error");
  assert.equal(e.message, "Linear: Authentication required, not authenticated");
  assert.ok(!e.message.includes("lin_api_secret"));
  assert.equal(calls[0].url, "https://api.linear.app/graphql");
  assert.deepEqual(Object.keys(calls[0].options).filter((k) => !["method", "headers", "body"].includes(k)), []);
  // An authentication error drops the key: the next read asks the login shell again.
  assert.equal(remote.tokens.has("LINEAR_API_KEY"), false);
}
{
  const good = setup({ answer: () => ok({ data: { issue: { state: { name: "Done", type: "completed", color: "#00ff00" }, updatedAt: "2026-01-01T00:00:00Z" } } }) });
  const e = await good.remote.entry(remoteRef(LINEAR_REF));
  assert.equal(e.status, "ok");
  assert.equal(e.value.kind, "done");
  const none = setup({ answer: () => ok({ data: { issue: null } }) });
  assert.equal((await none.remote.entry(remoteRef(LINEAR_REF))).message, "The tracker doesn't know this ticket.");
  // a rejected Linear token is dropped too
  const bad = setup({ tokens: ["a", "b"], answer: () => ({ status: 401, body: {} }) });
  await bad.remote.entry(remoteRef(LINEAR_REF));
  await bad.remote.entry(remoteRef(LINEAR_REF));
  assert.equal(bad.reads.length, 2);
}

console.log("beads-remote: ok");
