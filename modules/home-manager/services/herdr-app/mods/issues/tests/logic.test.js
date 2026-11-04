import { test } from "node:test";
import assert from "node:assert/strict";
import { jiraIssue, linearIssue, tokenOutput, projectKeys, issueKey, byStatus, jiraMarkdown, httpReason } from "../logic.js";
import { jira } from "../jira.js";
import { linear } from "../linear.js";

test("token output is trimmed and rejects empty or multiple lines", () => {
  assert.equal(tokenOutput("  synthetic-key\n"), "synthetic-key");
  for (const output of ["", " \n", "first\nsecond", "first\rsecond"]) assert.throws(() => tokenOutput(output));
});

test("Jira fields and linked issues normalize for the UI", () => {
  const issue = jiraIssue({ id: "1", key: "TEAM-9", fields: {
    summary: "Synthetic issue", description: "h2. Raw wiki", status: { id: "2", name: "Doing", statusCategory: { key: "indeterminate" } },
    assignee: { displayName: "Example" }, project: { name: "Demo" }, priority: { name: "High" }, issuetype: { name: "Bug" }, labels: ["test"],
    issuelinks: [{ outwardIssue: { key: "TEAM-8", fields: { summary: "Related" } } }],
  } }, "https://jira.example.com");
  assert.equal(issue.state.type, "started");
  assert.equal(issue.level, 2);
  assert.equal(issue.type, "Bug");
  assert.equal(issue.description, "h2. Raw wiki");
  assert.equal(issue.assignee, "Example");
  assert.equal(issue.links[0].url, "https://jira.example.com/browse/TEAM-8");
  assert.deepEqual(projectKeys('project in ("OTHER", TEAM) AND resolution = Unresolved', [issue]), ["TEAM", "OTHER"]);
  assert.equal(issueKey(" team-9 "), "TEAM-9");
  assert.throws(() => issueKey("not a key"));
});

test("Linear fields normalize without losing state, labels or links", () => {
  const issue = linearIssue({ id: "uuid", identifier: "DEMO-2", title: "Example", state: { name: "Done", type: "completed", color: "#123456" },
    labels: { nodes: [{ name: "test" }] }, attachments: { nodes: [{ title: "Link", url: "https://example.com" }] } });
  assert.equal(issue.identifier, "DEMO-2");
  assert.equal(issue.state.type, "completed");
  assert.equal(issue.description, "");
  assert.deepEqual(issue.labels, ["test"]);
  assert.equal(issue.links[0].title, "Link");
});

test("write actions send verbatim text and transition IDs (dry requests only)", async () => {
  const calls = [];
  const request = async (url, options) => {
    calls.push({ url, options });
    return { data: { issue: { id: "uuid" }, commentCreate: { success: true }, issueUpdate: { success: true } } };
  };
  const text = "  h2. Title\n*verbatim*\n";
  const jiraApi = jira({ url: "https://jira.example.com" }, request);
  await jiraApi.comment("TEAM-1", text);
  await jiraApi.transition("TEAM-1", "31");
  assert.deepEqual(JSON.parse(calls[0].options.body), { body: text });
  assert.deepEqual(JSON.parse(calls[1].options.body), { transition: { id: "31" } });
  assert.equal(calls[0].options.method, "POST");
  const linearApi = linear({}, request);
  await linearApi.comment("DEMO-2", text);
  await linearApi.transition("DEMO-2", "state-uuid");
  const mutations = calls.slice(2).map((c) => JSON.parse(c.options.body)).filter((c) => c.query.startsWith("mutation"));
  assert.deepEqual(mutations[0].variables.input, { issueId: "uuid", body: text });
  assert.deepEqual(mutations[1].variables, { id: "uuid", input: { stateId: "state-uuid" } });
});

test("issues group by status in the order work moves, review first", () => {
  const issue = (identifier, name, type) => ({ identifier, state: { name, type } });
  const groups = byStatus([issue("A-1", "Backlog", "backlog"), issue("A-2", "To Do", "unstarted"), issue("A-3", "In Progress", "started"),
    issue("A-4", "To Do", "unstarted"), issue("A-5", "In Review", "started")]);
  assert.deepEqual(groups.map((g) => [g.name, g.issues.map((i) => i.identifier)]),
    [["In Review", ["A-5"]], ["In Progress", ["A-3"]], ["To Do", ["A-2", "A-4"]], ["Backlog", ["A-1"]]]);
});

test("Jira wiki markup becomes Markdown for the issue screen", () => {
  const text = "h3. Summary\r\nOn *one* ({{a_b}}) see [docs|https://example.com/x], [~jdoe].\r\n||Tool||Verdict||\r\n|{{x}}|OK|\r\n* item\r\n{code:bash}\nexport A=1\n{code}";
  assert.equal(jiraMarkdown(text), "### Summary\nOn **one** (`a_b`) see [docs](https://example.com/x), @jdoe.  \n"
    + "| Tool | Verdict |\n| --- | --- |\n| `x` | OK |\n- item\n\n```\nexport A=1\n```\n");
});

test("a failed request says why in the tracker's words", () => {
  assert.equal(httpReason(404, '{"errorMessages":["Issue does not exist."],"errors":{}}'), "HTTP 404: Issue does not exist.");
  assert.equal(httpReason(401, '{"message":"Client must be authenticated."}'), "HTTP 401: Client must be authenticated.");
  assert.equal(httpReason(502, "<html><body>Bad   gateway</body></html>"), "HTTP 502: Bad gateway");
});
