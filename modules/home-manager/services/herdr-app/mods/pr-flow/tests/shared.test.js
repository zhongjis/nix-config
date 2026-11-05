import test from 'node:test';
import assert from 'node:assert/strict';
import { issueRefs } from '../issue-refs.js';
import { createTracker } from '../tracker.js';
import { checkState, ciSummary } from '../status.js';
import { createGh, parseRemote, parsePrUrl } from '../gh.js';
import { orderCards, conversation, descPreview } from '../present.js';
import { checkouts, ciRollup, githubRepo } from '../../tui-spaces/tracking.js';

test('CI reduction matches the detail check states; failure wins over pending', () => {
  const checks = [
    ...['FAILURE', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED', 'STARTUP_FAILURE', 'SUCCESS', 'NEUTRAL', 'SKIPPED'].map(conclusion => ({ status: 'COMPLETED', conclusion })),
    ...['FAILURE', 'ERROR', 'PENDING', 'SUCCESS'].map(state => ({ __typename: 'StatusContext', state })),
    { status: 'IN_PROGRESS', conclusion: null },
  ];
  const expected = { failed: 'fail', passed: 'pass', running: 'pending' };
  for (const check of checks) assert.equal(ciRollup([check]), expected[checkState(check)]);
  assert.equal(ciRollup([{ status: 'QUEUED' }, { state: 'ERROR' }]), 'fail');
  assert.equal(ciRollup([{ state: 'SUCCESS' }, { status: 'QUEUED' }]), 'pending');
  assert.equal(ciRollup([]), null);
});

test('checks are classified by where their details live; only Actions runs count for the CI panel', () => {
  const settings = { aiChecks: [], ciWaitMs: 0 };
  const summary = (rollup) => ciSummary({ statusCheckRollup: rollup }, { now: 0, headSeenAt: 0 }, settings);
  const app = { __typename: 'CheckRun', name: 'Kodiak', workflowName: '', status: 'COMPLETED', conclusion: 'SUCCESS', detailsUrl: 'https://wiki.example.com/Kodiak' };
  const job = { __typename: 'CheckRun', name: 'build', workflowName: 'CI', status: 'COMPLETED', conclusion: 'FAILURE', detailsUrl: 'https://github.com/o/r/actions/runs/42/job/7' };
  const sibling = { ...job, name: 'test', detailsUrl: 'https://github.com/o/r/actions/runs/42/job/8' };
  const ghe = { __typename: 'CheckRun', name: 'lint', workflowName: 'Lint', status: 'COMPLETED', conclusion: 'SUCCESS', detailsUrl: 'https://ghe.example.com/o/r/runs/99' };
  const status = { __typename: 'StatusContext', context: 'jenkins', state: 'SUCCESS', targetUrl: 'https://ci.example.com/1' };

  const external = summary([app, status]);
  assert.deepEqual(external.checks.map((c) => c.source), ['app', 'status']);
  assert.equal(external.actions, false);
  assert.equal(external.runs, 0);

  const mixed = summary([app, job, sibling, ghe]);
  assert.deepEqual(mixed.checks.map((c) => [c.source, c.runId]), [['app', null], ['actions', '42'], ['actions', '42'], ['actions', null]]);
  assert.equal(mixed.actions, true);
  assert.equal(mixed.runs, 1);
  assert.equal(mixed.failed[0].runId, '42');
});

test('worktrees skip bare/prunable entries and retain detached checkouts and spaces in paths', () => {
  const output = 'worktree /repo\nHEAD abc\nbranch refs/heads/main\n\nworktree /a branch\nHEAD def\nbranch refs/heads/topic\n\nworktree /detached\nHEAD abc\ndetached\n\nworktree /gone\nprunable gitdir missing\n\nworktree /bare\nbare\n';
  assert.deepEqual(checkouts(output), [{ folder: '/repo', branch: 'main' }, { folder: '/a branch', branch: 'topic' }, { folder: '/detached', branch: null }]);
  assert.equal(githubRepo('git@github.com:someone/project.git\n'), 'someone/project');
  assert.equal(githubRepo('https://github.com/someone/project.git'), 'someone/project');
  assert.equal(githubRepo('/local/repo'), null);
});

test('sidebar and panel share public, enterprise and SSH-alias identities', () => {
  const cases = [
    ['git@github.com:someone/project.git', 'someone/project'],
    ['git@github.com-personal:someone/project.git', 'someone/project'],
    ['git@github.com-work:someone/project.git', 'someone/project'],
    ['https://ghe.example.com/someone/project', 'ghe.example.com/someone/project'],
    ['git@ghe.example.com:someone/project.git', 'ghe.example.com/someone/project'],
    ['ssh://git@ghe.example.com/someone/project.git', 'ghe.example.com/someone/project'],
    ['https://gitlab.example.com/someone/project.git', 'gitlab.example.com/someone/project'],
  ];
  for (const [remote, expected] of cases) {
    assert.equal(githubRepo(remote), expected);
    assert.equal(parseRemote(remote), expected);
  }
  assert.deepEqual(parsePrUrl('https://ghe.example.com/someone/project/pull/42/files'), { host: 'ghe.example.com', owner: 'someone', name: 'project', repo: 'ghe.example.com/someone/project', number: 42, url: 'https://ghe.example.com/someone/project/pull/42' });
  assert.equal(parsePrUrl('https://github.com/someone/project/pull/42').repo, 'someone/project');
});

test('enterprise detail commands keep host-qualified repos out of API paths', async () => {
  const calls = [];
  const gh = createGh(async (_command, args) => {
    calls.push(args);
    const response = args[1] === 'graphql' ? { data: { repository: { pullRequest: { reviewThreads: { nodes: [] }, commits: { nodes: [] } } } } }
      : args[1].endsWith('/jobs?per_page=50') ? { jobs: [] } : { workflow_runs: [] };
    return { code: 0, stdout: JSON.stringify(response) };
  });
  const repo = 'ghe.example.com/someone/project', url = 'https://ghe.example.com/someone/project/pull/42';
  await gh.fetchPr(url);
  await gh.fetchThreads(url);
  await gh.fetchRuns(repo, 'abc');
  await gh.fetchJobs(repo, 7);
  await gh.failedLog(repo, 7);
  assert.deepEqual(calls[0].slice(0, 5), ['pr', 'view', url, '-R', repo]);
  for (const args of calls.filter(args => args[0] === 'api')) assert.equal(args[args.indexOf('--hostname') + 1], 'ghe.example.com');
  assert.equal(calls[2][1], 'repos/someone/project/actions/runs?head_sha=abc&per_page=50');
  assert.equal(calls[3][1], 'repos/someone/project/actions/runs/7/jobs?per_page=50');
  assert.deepEqual(calls[4], ['run', 'view', 7, '-R', repo, '--log-failed']);
});

test('issue chips deduplicate providers, honor Jira host/projects, and detect Linear without settings', () => {
  const body = 'Fix PROJ-12 and OTHER-8. https://jira.example.com/browse/PROJ-12 https://other.example.com/browse/OTHER-9 https://linear.app/team/issue/ENG-7/title';
  assert.deepEqual(issueRefs(body, { jiraHost: 'https://jira.example.com', projectKeys: ['PROJ'] }), [{ provider: 'jira', key: 'PROJ-12' }, { provider: 'linear', key: 'ENG-7' }]);
  assert.deepEqual(issueRefs(body), [{ provider: 'jira', key: 'PROJ-12' }, { provider: 'jira', key: 'OTHER-9' }, { provider: 'linear', key: 'ENG-7' }]);
  assert.deepEqual(issueRefs('https://linear.app.evil/team/issue/ENG-7 XPROJ-12', { projectKeys: ['PROJ'] }), []);
});

test('shared summaries need no requests; only the selected PR fetches detail with backoff', async () => {
  let now = 0;
  const calls = [];
  const tracker = createTracker({ now: () => now, gh: {
    fetchPr: async url => { calls.push(url); return { title: 'detail', body: 'PROJ-1', state: 'OPEN', headRefName: 'topic', statusCheckRollup: [] }; },
    fetchThreads: async () => ({ threads: [], issues: [] }),
  } });
  const prs = [1, 2].map(number => ({ number, title: `PR ${number}`, url: `https://github.com/owner/repo/pull/${number}`, branch: `topic${number}`, ci: 'fail', review: 'APPROVED' }));
  tracker.sync({ 'owner/repo': prs });
  assert.equal(tracker.cards().length, 2);
  assert.equal(tracker.cards()[0].status.ci.kind, 'failed');
  await tracker.tick(null);
  assert.deepEqual(calls, []);
  await tracker.tick(prs[1].url);
  assert.deepEqual(calls, [prs[1].url]);
  assert.equal(tracker.cards(prs[1].url)[1].summary, false);
  tracker.sync({ 'owner/repo': [{ ...prs[0], ci: 'pass' }, prs[1]] });
  assert.equal(tracker.cards()[0].status.ci.kind, 'passed');
  await tracker.tick(prs[1].url);
  assert.equal(calls.length, 1);
  now += 30000;
  await tracker.tick(prs[1].url);
  assert.equal(calls.length, 2);
  tracker.sync({ 'owner/repo': [prs[0]] });
  assert.equal(tracker.cards().length, 1);
});

test('yours first, checked-out branch leads its group, bots trail people, newest first', () => {
  const cards = [
    { number: 1, bot: true, updatedAt: '2026-01-09' },
    { number: 2, updatedAt: '2026-01-01' },
    { number: 3, mine: true, updatedAt: '2026-01-02' },
    { number: 4, updatedAt: '2026-01-05' },
    { number: 5, mine: true, updatedAt: '2026-01-03' },
    { number: 6, branch: 'topic', updatedAt: '2026-01-00' },
    { number: 7, mine: true, branch: 'topic', updatedAt: '2026-01-00' },
  ];
  assert.deepEqual(orderCards(cards, 'topic').map(c => c.number), [7, 5, 3, 6, 4, 2, 1]);
});

test('conversation: people and bots oldest first, silent reviews dropped, back-to-back bots folded', () => {
  const user = (login) => ({ login, __typename: 'User' });
  const card = {
    comments: [
      { author: { login: 'coderabbitai', __typename: 'Bot' }, body: '<!-- x -->\n## ⚠️ **Walkthrough**\nlong', createdAt: '2026-01-02', url: 'c2' },
      { author: user('alice'), body: 'Looks off', createdAt: '2026-01-05', url: 'c5' },
      { author: { login: 'app/renovate' }, body: 'Rebased', createdAt: '2026-01-01', url: 'c1' },
    ],
    reviews: [
      { author: user('bob'), body: '', state: 'APPROVED', submittedAt: '2026-01-04', url: 'r4' },
      { author: user('bob'), body: 'LGTM', state: 'APPROVED', submittedAt: '2026-01-06', url: 'r6' },
      { author: { login: 'chatgpt-codex-connector', __typename: 'Bot' }, body: 'Review', state: 'COMMENTED', submittedAt: '2026-01-03', url: 'r3' },
    ],
    threads: [
      { isResolved: false, isOutdated: false, path: 'src/a.js', line: 7, comments: { nodes: [{ author: user('carol'), body: 'nit', createdAt: '2026-01-07', url: 't7' }] } },
      { isResolved: true, isOutdated: false, path: 'src/b.js', line: 1, comments: { nodes: [{ author: user('carol'), body: 'done', createdAt: '2026-01-08', url: 't8' }] } },
    ],
  };
  const out = conversation(card);
  assert.deepEqual(out.map((x) => x.kind === 'bots' ? x.items.map((i) => i.key) : x.key), [['c1', 'c2', 'r3'], 'c5', 'r6', 't7']);
  assert.deepEqual(out[0].items.map((i) => i.who), ['renovate', 'coderabbitai', 'chatgpt-codex-connector']);
  assert.equal(out[0].items[1].line, 'Walkthrough');
  assert.deepEqual(out.slice(1).map((x) => x.bot), [false, false, false]);
  assert.equal(out[3].where, 'src/a.js:7');
});

test('description preview keeps the first section\'s prose and says when more is hidden', () => {
  const body = '## Summary\nPromote the endpoint.\n\n```mermaid\nA\n\nB\n```\n\n## Changes\n- route';
  assert.deepEqual(descPreview(body), { preview: 'Promote the endpoint.', more: true });
  assert.deepEqual(descPreview('Fixes the thing.'), { preview: 'Fixes the thing.', more: false });
});
