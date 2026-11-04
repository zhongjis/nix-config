import { jiraIssue, jiraState } from "./logic.js";

const LIST = "summary,status,assignee,priority,project,issuetype,labels,updated";
const FIELDS = `${LIST},description,issuelinks`;

export function jira(config, request) {
  const host = config.url.replace(/\/+$/, "");
  const path = (key) => `${host}/rest/api/2/issue/${encodeURIComponent(key)}`;
  const normalize = (raw) => jiraIssue(raw, host);
  return {
    label: "Jira", syntax: "Jira wiki markup", where: host.replace(/^https?:\/\//, ""),
    async mine() {
      await request(`${host}/rest/api/2/myself`);
      const all = [];
      for (;;) {
        const page = await request(`${host}/rest/api/2/search?jql=${encodeURIComponent(config.jql)}&fields=${LIST}&startAt=${all.length}&maxResults=100`);
        all.push(...page.issues.map(normalize));
        if (all.length >= page.total) return all;
        if (!page.issues.length) throw new Error("Jira search returned an incomplete page. Refresh to retry.");
      }
    },
    async get(key) { return normalize(await request(`${path(key)}?fields=${FIELDS}`)); },
    async comments(key) {
      const all = [];
      for (;;) {
        const page = await request(`${path(key)}/comment?startAt=${all.length}&maxResults=100`);
        all.push(...page.comments.map((c) => ({ id: c.id, body: c.body, author: c.author?.displayName ?? "Unknown", created: c.created })));
        if (all.length >= page.total) return all;
        if (!page.comments.length) throw new Error("Jira comments returned an incomplete page. Refresh to retry.");
      }
    },
    comment(key, text) { return request(`${path(key)}/comment`, { method: "POST", body: JSON.stringify({ body: text }) }); },
    async transitions(key) {
      return (await request(`${path(key)}/transitions`)).transitions.map((t) => ({ id: t.id, name: t.name, state: jiraState(t.to) }));
    },
    transition(key, id) { return request(`${path(key)}/transitions`, { method: "POST", body: JSON.stringify({ transition: { id } }) }); },
    url(key) { return `${host}/browse/${encodeURIComponent(key)}`; },
  };
}
