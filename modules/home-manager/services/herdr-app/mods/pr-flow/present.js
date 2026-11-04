// Turns a card into what the screens say. Facts only: no "needs you" or "in progress" buckets.
import { relative } from './i18n.js';
import { flowSummary, orderedRuns, position, runState, visibleSteps } from './flow.js';
import { sanitize } from './text.js';

const latest = (values) => values.map((v) => Date.parse(v) || 0).reduce((a, b) => Math.max(a, b), 0);

function ciFact(ci, t) {
  if (ci.kind === 'failed') return { tone: 'bad', label: t('ci_failed') };
  if (ci.kind === 'running') return { tone: 'run', label: t('ci_running') };
  if (ci.kind === 'passed') return { tone: 'ok', label: t('ci') };
  return { tone: 'dim', label: t('ci_none') };
}

const REVIEW = {
  approved: ['ok', 'r_approved'], changes: ['warn', 'r_changes'], ai_running: ['run', 'r_ai'],
  required: ['wait', 'r_wait'], reviewed: ['ok', 'r_reviewed'], none: ['dim', 'r_none'],
};

// The list row's line: what finished and what is happening, in order.
export function facts(card, t) {
  const { status, pr } = card;
  if (status.name === 'merged') return [{ tone: 'merged', label: pr.baseRefName ? t('merged_to', pr.baseRefName) : t('merged') }];
  if (status.name === 'closed') return [{ tone: 'dim', label: t('closed') }];
  const out = [];
  if (status.name === 'draft') out.push({ tone: 'dim', label: t('draft') });
  out.push(ciFact(status.ci, t));
  if (status.ci.kind === 'running' && status.ci.total) out.push({ tone: 'dim', label: `${status.ci.checks.filter((c) => c.state !== 'running').length}/${status.ci.total}` });
  const [tone, key] = REVIEW[status.review];
  if (status.name !== 'draft') out.push({ tone, label: t(key) });
  if (status.comments) out.push({ tone: 'comment', label: String(status.comments) });
  if (status.name === 'conflict') out.push({ tone: 'bad', label: t('conflict') });
  // UNKNOWN means GitHub hasn't worked it out yet, so don't claim anything.
  if (status.name === 'ready' && pr.mergeable === 'MERGEABLE') out.push({ tone: 'merge', label: t('ready') });
  return out;
}

function ciStep(status, t, ago) {
  const { ci } = status;
  if (ci.kind === 'failed') return { tone: 'bad', label: t('s_failed'), checks: true, note: ci.failed.map((c) => c.name).join(', ') };
  if (ci.kind === 'running') return { tone: 'run', label: t('s_running'), checks: true, note: ci.total ? t('n_of', ci.checks.filter((c) => c.state !== 'running').length, ci.total) : '' };
  if (ci.kind === 'passed') {
    const at = latest(ci.checks.map((c) => c.at));
    return { tone: 'ok', label: t('s_passed'), checks: true, note: [t('n_checks', ci.total), at ? ago(at) : ''].filter(Boolean).join(' · ') };
  }
  return { tone: 'todo', label: t('s_none'), note: '' };
}

function reviewStep(card, t, ago) {
  const { status, pr } = card;
  const reviews = pr.latestReviews ?? [];
  const by = (state) => reviews.filter((r) => r.state === state);
  const note = (list) => {
    if (!list.length) return '';
    const at = latest(list.map((r) => r.submittedAt));
    return [at ? ago(at) : '', list.map((r) => r.author?.login).filter(Boolean).join(', ')].filter(Boolean).join(' · ');
  };
  switch (status.review) {
    case 'approved': return { tone: 'ok', label: t('r_approved'), note: note(by('APPROVED')) };
    case 'changes': return { tone: 'warn', label: t('r_changes'), note: note(by('CHANGES_REQUESTED')) };
    case 'ai_running': return { tone: 'run', label: t('r_ai'), note: status.ci.ai.filter((c) => c.state === 'running').map((c) => c.name).join(', ') };
    case 'required': return { tone: 'wait', label: t('r_wait'), note: '' };
    case 'reviewed': return { tone: 'ok', label: t('r_reviewed'), note: note(reviews) };
    default: return { tone: 'todo', label: t('r_none'), note: '' };
  }
}

function endStep(card, t, ago) {
  const { status, pr } = card;
  if (status.name === 'merged') return { tone: 'merged', label: pr.baseRefName ? t('merged_to', pr.baseRefName) : t('merged'), note: pr.mergedAt ? ago(Date.parse(pr.mergedAt)) : '' };
  if (status.name === 'closed') return { tone: 'todo', label: t('closed'), note: pr.closedAt ? ago(Date.parse(pr.closedAt)) : '' };
  if (status.name === 'conflict') return { tone: 'bad', label: t('conflict'), note: '' };
  if (pr.mergeStateStatus === 'BEHIND') return { tone: 'warn', label: t('behind'), note: '' };
  if (pr.mergeStateStatus === 'BLOCKED' && status.ci.kind !== 'failed' && status.review === 'approved') return { tone: 'warn', label: t('blocked'), note: '' };
  if (status.name === 'ready' && pr.mergeable === 'MERGEABLE') return { tone: 'merge', label: t('ready'), note: '' };
  return null; // nothing to say yet: CI and review already tell why
}

// The detail's status lines, one per field: CI, review, and merge when it has a fact.
export function statusRows(card, t, now) {
  const ago = (at) => relative(now - at, t);
  const merge = endStep(card, t, ago);
  return [
    { key: 'ci', field: t('ci'), ...ciStep(card.status, t, ago) },
    { key: 'review', field: t('review'), ...reviewStep(card, t, ago) },
    ...(merge ? [{ key: 'merge', field: t('merge'), ...merge }] : []),
  ];
}

const isBot = (author) => author?.__typename === 'Bot' || String(author?.login ?? '').startsWith('app/');

// A post's first readable line, for a folded row: no markup, images, code or HTML.
export function firstLine(markdown) {
  return String(markdown ?? '')
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/(```|~~~)[\s\S]*?(\1|$)/g, '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .split('\n')
    .map((l) => l.replace(/^\s*(#{1,6}\s+|>\s*|[-*+]\s+|\d+\.\s+)/, '').replace(/\*\*|__|`|~~|\p{Extended_Pictographic}\uFE0F?/gu, '').replace(/\s+/g, ' ').trim())
    .find((l) => l && !/^[-=*_]{3,}$/.test(l)) ?? '';
}

// The PR's discussion, oldest first: comments, reviews that say something, and open
// review threads. Back-to-back bot posts fold into one group.
export function conversation(card) {
  const item = (kind, node, at, extra) => {
    const body = sanitize(node.body).trim(), who = String(node.author?.login ?? 'ghost').replace(/^app\//, '');
    return { kind, key: node.url || `${kind}:${who}:${at}`, who, bot: isBot(node.author), at, body, line: firstLine(body), ...extra };
  };
  const items = [
    ...(card.comments ?? []).map((c) => item('comment', c, c.createdAt)),
    ...(card.reviews ?? []).filter((r) => r.submittedAt && r.body?.trim()).map((r) => item('review', r, r.submittedAt, { state: r.state })),
    ...(card.threads ?? []).filter((x) => !x.isResolved && !x.isOutdated && x.comments?.nodes?.[0]).map((x) =>
      item('thread', x.comments.nodes[0], x.comments.nodes[0].createdAt, { where: x.line ? `${x.path}:${x.line}` : String(x.path ?? '') })),
  ].filter((i) => i.body).sort((a, b) => (Date.parse(a.at) || 0) - (Date.parse(b.at) || 0));
  return items.reduce((out, i) => {
    const last = out.at(-1);
    if (!i.bot || !last?.bot) return [...out, i];
    const group = last.kind === 'bots' ? last : { kind: 'bots', bot: true, key: last.key, items: [last] };
    return [...out.slice(0, -1), { ...group, items: [...group.items, i] }];
  }, []);
}

// The description's opening prose for the folded view: its first section's paragraphs
// and lists, about `min` characters, without headings, code, tables or HTML.
export function descPreview(body, min = 200) {
  const text = String(body ?? '').trim(), blocks = [];
  let block = [], fence = false;
  for (const line of text.split('\n')) {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    if (fence || line.trim()) block.push(line);
    else if (block.length) { blocks.push(block); block = []; }
  }
  if (block.length) blocks.push(block);
  const head = [];
  for (const lines of blocks) {
    const prose = lines.filter((l) => !/^\s*(#{1,6}(\s|$)|[-*_=]{3,}\s*$)/.test(l));
    if (head.length && prose.length < lines.length) break; // the next section starts
    if (!prose.length || /^\s*(```|~~~|<|\|)/.test(prose[0])) continue;
    head.push(prose.join('\n'));
    if (head.join('').length >= min) break;
  }
  const preview = head.join('\n\n');
  return { preview, more: preview !== text };
}

// Log shown in the panel: the end of it, where the failure usually is.
export function logTail(log, count = 8) {
  const lines = String(log ?? '').split('\n').map((l) => l.trimEnd()).filter((l) => l.trim());
  return lines.slice(-count);
}

const TONE = { ok: 'ok', bad: 'bad', running: 'run', waiting: 'wait', queued: 'wait', cancelled: 'todo' };

function whereNow(run, jobs, t) {
  const state = runState(run);
  if (state === 'waiting') return t('flow_waiting');
  if (state === 'queued') return t('flow_queued');
  const at = position(jobs);
  return at?.step ? `${at.step} (${at.index}/${at.total})` : '';
}

// The list row's second line after a merge. Null when nothing runs.
export function flowLine(card, t) {
  const flow = card.flow;
  if (!flow) return null;
  const summary = flowSummary(flow.runs);
  if (summary.kind === 'none') return flow.active ? { tone: 'run', label: t('flow_checking'), more: '' } : null;
  const more = summary.more ? t('flow_more', summary.more) : '';
  if (summary.kind === 'done') return { tone: 'ok', label: t('flow_done', summary.total), more: '' };
  const { lead } = summary;
  if (summary.kind === 'failed') return { tone: 'bad', label: t('flow_failed', lead.name), more };
  const where = whereNow(lead, flow.jobs?.[lead.id]?.jobs, t);
  return { tone: TONE[runState(lead)], label: where ? `${lead.name} · ${where}` : lead.name, more };
}

// One timeline row per workflow run, most urgent first.
export function flowRows(card, t, now) {
  const flow = card.flow;
  if (!flow) return [];
  return orderedRuns(flow.runs).map((run) => {
    const state = runState(run);
    const when = run.updatedAt ? relative(now - Date.parse(run.updatedAt), t) : '';
    const note = state === 'ok' ? when
      : state === 'bad' ? [t('flow_failed_note'), when].filter(Boolean).join(' · ')
      : state === 'cancelled' ? [t('flow_cancelled'), when].filter(Boolean).join(' · ')
      : whereNow(run, flow.jobs?.[run.id]?.jobs, t);
    return { id: run.id, url: run.url, tone: TONE[state], label: run.name, note, failed: state === 'bad' };
  });
}

// The steps under an opened run, without the ones GitHub adds to every job.
export function jobSteps(jobs) {
  return (jobs ?? []).map((job) => ({ name: job.name, tone: TONE[runState(job)] ?? 'todo', steps: visibleSteps(job).map((s) => ({ name: s.name, tone: s.status === 'pending' ? 'todo' : TONE[runState(s)] ?? 'todo' })) }));
}

export function issueState(issue, t) {
  if (issue.state === 'OPEN') return { tone: 'ok', label: t('issue_open') };
  if (issue.stateReason === 'NOT_PLANNED') return { tone: 'dim', label: t('issue_not_planned') };
  return { tone: 'merged', label: t('issue_closed') };
}

// Shown on every row, like "no CI": a missing link is a fact too.
export function issueLabel(card, t) {
  const issues = card.issues ?? [];
  if (!issues.length) return t('issue_none');
  return issues.length === 1 ? t('issue_one', issues[0].number) : t('issue_many', issues.length);
}

// The owners (users or organizations) in the list, most PRs first: [[owner, count]].
export function orgsOf(cards) {
  const counts = new Map();
  for (const c of cards) { const owner = String(c.repo).split('/')[0]; counts.set(owner, (counts.get(owner) ?? 0) + 1); }
  return [...counts].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
}

// Your PRs first, then others; the checked-out branch leads its group, bots
// trail the people, newest update first within each.
export function orderCards(cards, branch) {
  const rank = (c) => [c.mine ? 0 : 1, c.branch === branch ? 0 : 1, c.bot ? 1 : 0];
  return [...cards].sort((a, b) => {
    const ra = rank(a), rb = rank(b);
    for (let i = 0; i < ra.length; i++) if (ra[i] !== rb[i]) return ra[i] - rb[i];
    return String(b.updatedAt ?? '').localeCompare(String(a.updatedAt ?? ''));
  });
}

// The cards of one owner; all of them when `org` is null or has none left.
export function byOrg(cards, org) {
  if (!org) return cards;
  const mine = cards.filter((c) => String(c.repo).split('/')[0] === org);
  return mine.length ? mine : cards;
}
