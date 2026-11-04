// Issue references from PR prose, independent of the popup's provider clients.
export function issueRefs(body, refs) {
  const found = new Map();
  const add = (provider, key) => found.set(`${provider}:${key}`, { provider, key });
  const host = refs?.jiraHost?.replace(/^https?:\/\//i, '').split('/')[0].toLowerCase();
  const text = String(body ?? '');
  for (const match of text.matchAll(/https?:\/\/([^/\s)]+)(\/[^\s)<>"]*)/gi)) {
    const domain = match[1].toLowerCase(), path = match[2];
    const linear = /^\/[^/]+\/issue\/([A-Z][A-Z0-9_]*-\d+)(?=[/?#.,;:!\s]|$)/i.exec(path);
    const jira = /\/browse\/([A-Z][A-Z0-9_]*-\d+)(?=[/?#.,;:!\s]|$)/i.exec(path);
    if (domain === 'linear.app' && linear) add('linear', linear[1].toUpperCase());
    else if ((!host || domain === host) && jira) add('jira', jira[1].toUpperCase());
  }
  const projects = new Set((refs?.projectKeys ?? []).map(k => k.toUpperCase()));
  const prose = text.replace(/https?:\/\/[^\s)<>"]+/gi, '');
  for (const match of prose.matchAll(/\b([A-Z][A-Z0-9_]*-\d+)\b/g)) {
    if (projects.has(match[1].slice(0, match[1].lastIndexOf('-')))) add('jira', match[1]);
  }
  return [...found.values()];
}
