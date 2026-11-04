import { linearIssue } from "./logic.js";

const FIELDS = "id identifier title description url updatedAt priority priorityLabel state { id name type color } assignee { displayName } project { name } labels { nodes { name } }";
const PAGE = "pageInfo { hasNextPage endCursor }";

export function linear(_config, request) {
  const query = async (query, variables = {}) => {
    const result = await request("https://api.linear.app/graphql", { method: "POST", body: JSON.stringify({ query, variables }) });
    if (result.errors?.length) throw new Error(result.errors.map((e) => e.message).join("\n"));
    return result.data;
  };
  const get = async (key) => {
    const data = await query(`query($key: String!) { issue(id: $key) { ${FIELDS} attachments { nodes { title url } } } }`, { key });
    if (!data.issue) throw new Error("Issue not found.");
    return linearIssue(data.issue);
  };
  return {
    label: "Linear", syntax: "Markdown", where: "Linear · experimental",
    async mine() {
      const all = [];
      let after = null;
      do {
        const data = await query(`query($after: String) { viewer { assignedIssues(first: 100, after: $after, orderBy: updatedAt, filter: { state: { type: { nin: ["completed", "canceled"] } } }) { nodes { ${FIELDS} } ${PAGE} } } }`, { after });
        const page = data.viewer.assignedIssues;
        all.push(...page.nodes.map(linearIssue));
        if (!page.pageInfo.hasNextPage) return all;
        if (!page.nodes.length || page.pageInfo.endCursor === after) throw new Error("Linear returned an incomplete page. Refresh to retry.");
        after = page.pageInfo.endCursor;
      } while (after);
      throw new Error("Linear returned no continuation cursor.");
    },
    get,
    async comments(key) {
      const all = [];
      let after = null;
      do {
        const data = await query(`query($key: String!, $after: String) { issue(id: $key) { comments(first: 100, after: $after) { nodes { id body createdAt user { displayName } } ${PAGE} } } }`, { key, after });
        const page = data.issue.comments;
        all.push(...page.nodes.map((c) => ({ id: c.id, body: c.body, author: c.user?.displayName ?? "Unknown", created: c.createdAt })));
        if (!page.pageInfo.hasNextPage) return all;
        if (!page.nodes.length || page.pageInfo.endCursor === after) throw new Error("Linear comments returned an incomplete page.");
        after = page.pageInfo.endCursor;
      } while (after);
      throw new Error("Linear returned no continuation cursor.");
    },
    async comment(key, text) {
      const issue = await get(key);
      const data = await query("mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }", { input: { issueId: issue.id, body: text } });
      if (!data.commentCreate.success) throw new Error("Linear did not create the comment.");
    },
    async transitions(key) {
      const data = await query("query($key: String!) { issue(id: $key) { team { states { nodes { id name type color position } } } } }", { key });
      return [...data.issue.team.states.nodes].sort((a, b) => a.position - b.position)
        .map((s) => ({ id: s.id, name: s.name, state: { id: s.id, name: s.name, type: s.type, color: s.color } }));
    },
    async transition(key, id) {
      const issue = await get(key);
      const data = await query("mutation($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success } }", { id: issue.id, input: { stateId: id } });
      if (!data.issueUpdate.success) throw new Error("Linear did not update the status.");
    },
    async url(key) { return (await get(key)).url; },
  };
}
