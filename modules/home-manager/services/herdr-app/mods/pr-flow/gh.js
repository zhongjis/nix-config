// Every call here only reads. PR Flow never writes to GitHub.
// `exec` is the app's: (command, args, options) => Promise<{code, stdout, stderr}>.
const PR_FIELDS = [
  'number', 'title', 'body', 'url', 'state', 'isDraft', 'headRefName', 'headRefOid', 'baseRefName',
  'statusCheckRollup', 'reviewDecision', 'latestReviews', 'mergeStateStatus', 'mergeable',
  'additions', 'deletions', 'changedFiles', 'files', 'createdAt', 'mergedAt', 'closedAt', 'updatedAt', 'mergeCommit',
].join(',');

const THREADS_QUERY = `query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){
  reviewThreads(first:100){nodes{isResolved isOutdated path line comments(first:1){nodes{author{login __typename} body createdAt url}}}}
  comments(last:50){nodes{author{login __typename} body createdAt url}}
  reviews(last:50){nodes{author{login __typename} body state submittedAt url}}
  commits(last:1){nodes{commit{committedDate}}}
  closingIssuesReferences(first:10){nodes{number title state stateReason url repository{nameWithOwner}}}
}}}`;

export function parsePrUrl(url) {
  const m = /^https:\/\/([^/\s]+)\/([^/\s]+)\/([^/\s]+)\/pull\/(\d+)(?:[/?#]|$)/.exec(String(url));
  if (!m) return null;
  const host = m[1].toLowerCase().replace(/^github\.com-.+$/, 'github.com');
  return { host, owner: m[2], name: m[3], repo: `${host === 'github.com' ? '' : host + '/'}${m[2]}/${m[3]}`, number: Number(m[4]), url: `https://${host}/${m[2]}/${m[3]}/pull/${m[4]}` };
}

export function parseRemote(remote) {
  const match = /^(?:git@([^:/\s]+):|https?:\/\/([^/\s]+)\/|ssh:\/\/git@([^/\s]+)\/)([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(String(remote).trim());
  if (!match) return null;
  const host = (match[1] ?? match[2] ?? match[3]).toLowerCase().replace(/^github\.com-.+$/, 'github.com');
  return `${host === 'github.com' ? '' : host + '/'}${match[4]}/${match[5]}`;
}

// `gh run view --log-failed` prefixes every line with job, step and timestamp.
export function cleanRunLog(log) {
  return String(log)
    .split('\n')
    .map((line) => line.replace(/^[^\t]*\t[^\t]*\t﻿?\d{4}-\d{2}-\d{2}T[\d:.]+Z ?/, ''))
    .filter((line) => !/^##\[(group|endgroup)\]/.test(line))
    .map((line) => line.replace(/^##\[[a-z]+\]/, ''))
    .join('\n');
}

export function runIdFromUrl(url) {
  const m = /\/actions\/runs\/(\d+)/.exec(url ?? '');
  return m ? m[1] : null;
}

export function createGh(exec) {
  const run = async (args) => {
    const r = await exec('gh', args);
    if (r.code !== 0) throw new Error(String(r.stderr).trim() || `gh ${args[0]} failed`);
    return String(r.stdout);
  };
  const json = async (args) => JSON.parse(await run(args));
  const api = (repo, endpoint, args = []) => {
    const parts = repo.split('/');
    const host = parts.length === 3 ? parts.shift() : 'github.com';
    const path = endpoint === 'graphql' ? endpoint : `repos/${parts.join('/')}/${endpoint}`;
    return json(['api', path, ...(host === 'github.com' ? [] : ['--hostname', host]), ...args]);
  };
  return {
    fetchPr: (url) => json(['pr', 'view', url, '-R', parsePrUrl(url).repo, '--json', PR_FIELDS]),
    fetchThreads: async (url) => {
      const p = parsePrUrl(url);
      const data = await api(p.repo, 'graphql', ['-f', `query=${THREADS_QUERY}`, '-F', `owner=${p.owner}`, '-F', `name=${p.name}`, '-F', `number=${p.number}`]);
      const pull = data.data.repository.pullRequest;
      return { threads: pull.reviewThreads.nodes, issues: pull.closingIssuesReferences?.nodes ?? [], comments: pull.comments?.nodes ?? [], reviews: pull.reviews?.nodes ?? [], headCommittedAt: pull.commits.nodes[0]?.commit.committedDate ?? null };
    },
    fetchRuns: async (repo, sha) => (await api(repo, `actions/runs?head_sha=${sha}&per_page=50`)).workflow_runs.map((r) => ({
      id: r.id, name: r.name ?? r.display_title ?? 'workflow', status: r.status, conclusion: r.conclusion, url: r.html_url, updatedAt: r.updated_at,
    })),
    fetchJobs: async (repo, runId) => (await api(repo, `actions/runs/${runId}/jobs?per_page=50`)).jobs.map((j) => ({
      id: j.id, name: j.name, status: j.status, conclusion: j.conclusion, steps: (j.steps ?? []).map((x) => ({ number: x.number, name: x.name, status: x.status, conclusion: x.conclusion })),
    })),
    fetchIssue: (url) => json(['issue', 'view', url, '--json', 'number,title,state,stateReason,body,author,labels,comments,url,createdAt']),
    fetchDiff: (url) => run(['pr', 'diff', url, '--color', 'never']),
    failedLog: async (repo, runId) => cleanRunLog(await run(['run', 'view', runId, '-R', repo, '--log-failed'])),
    authOk: async () => (await exec('gh', ['auth', 'status'])).code === 0,
  };
}
