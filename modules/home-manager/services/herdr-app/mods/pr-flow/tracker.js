// The sidebar owns discovery. Only the open PR costs detail requests here.
import { prState } from './status.js';
import { sanitize } from './text.js';
import { flowActive } from './flow.js';

export function createTracker({ gh, now = Date.now }) {
  let entries = [], error = '';
  const live = new Map(), pending = new Set();
  const settings = { aiChecks: [], ciWaitMs: 0 };

  function sync(prs) {
    entries = Object.entries(prs ?? {}).flatMap(([repo, list]) => list.map(p => ({ ...p, repo })));
  }

  async function refresh(url) {
    if (!url || pending.has(url) || !entries.some(e => e.url === url)) return;
    pending.add(url);
    try {
      const [pr, extra] = await Promise.all([gh.fetchPr(url), gh.fetchThreads(url)]);
      const data = { pr: { ...pr, title: sanitize(pr.title), body: sanitize(pr.body) }, threads: extra.threads, issues: extra.issues ?? [], comments: extra.comments ?? [], reviews: extra.reviews ?? [], at: now(), flow: null };
      if (pr.state === 'MERGED' && pr.mergeCommit?.oid) {
        const runs = await gh.fetchRuns(entries.find(e => e.url === url).repo, pr.mergeCommit.oid);
        data.flow = { runs, jobs: live.get(url)?.flow?.jobs ?? {}, active: flowActive(runs, pr.mergedAt, now()) };
      }
      live.set(url, data);
      error = '';
    } catch (e) {
      error = e.message;
      live.set(url, { ...live.get(url), error, at: now() });
    } finally { pending.delete(url); }
  }

  async function tick(url) {
    if (url && now() - (live.get(url)?.at ?? -Infinity) >= 30000) await refresh(url);
  }

  function cards(detailUrl) {
    return entries.map(e => {
      const data = e.url === detailUrl ? live.get(e.url) : null;
      const pr = data?.pr ?? { title: sanitize(e.title), headRefName: e.branch, state: 'OPEN', reviewDecision: e.review, updatedAt: e.updatedAt };
      const status = prState(pr, { now: now(), headSeenAt: 0, threads: data?.threads }, settings);
      if (!data?.pr) status.ci.kind = ({ pass: 'passed', fail: 'failed', pending: 'running' })[e.ci] ?? 'none';
      return { ...e, key: e.url, pr, summary: !data?.pr, status, threads: data?.threads ?? [], issues: data?.issues ?? [], comments: data?.comments ?? [], reviews: data?.reviews ?? [], flow: data?.flow, error: data?.error };
    });
  }

  async function loadJobs(url, runId) {
    const entry = entries.find(e => e.url === url), flow = live.get(url)?.flow;
    if (!entry || !flow || flow.jobs[runId]?.final) return;
    const jobs = await gh.fetchJobs(entry.repo, runId).catch(() => null);
    if (jobs) flow.jobs[runId] = { jobs, final: flow.runs.find(r => r.id === runId)?.status === 'completed' };
  }

  return { sync, tick, cards, refresh, loadJobs, lastError: () => error };
}
