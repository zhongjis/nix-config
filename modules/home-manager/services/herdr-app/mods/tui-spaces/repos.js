// One discovery per checkout group, one PR request per GitHub repo. Failed
// remotes/gh calls wait five minutes; remote machines never use local gh auth.
import { exec, shared, setShared } from "herdr";
import { checkouts, ciRollup, githubRepo } from "./tracking.js";

export class Repositories {
  constructor() {
    this.groups = {};
    this.prs = {};
  }

  refresh(g, cx) {
    const group = this.groups[g.repo] ??= { worktrees: [], at: 0 };
    if (group.busy || Date.now() < group.at) return;
    group.busy = true;
    cx.spawn(async cx => {
      const [on] = JSON.parse(g.repo);
      group.at = Date.now() + 60000;
      try {
        const result = await exec("git", ["-c", "core.quotePath=false", "worktree", "list", "--porcelain"], { cwd: g.folder, on });
        if (result.code !== 0) throw new Error("worktrees unavailable");
        group.worktrees = checkouts(result.stdout);
        if (on) return;
        const cwd = group.worktrees[0]?.folder ?? g.folder;
        if (!group.github) {
          const remote = await exec("git", ["remote", "get-url", "origin"], { cwd });
          group.github = remote.code === 0 ? githubRepo(remote.stdout) : null;
        }
        if (!group.github) { group.at = Date.now() + 300000; return; }
        const cache = this.prs[group.github] ??= { at: 0, list: [] };
        if (cache.busy || Date.now() < cache.at) return;
        cache.busy = true;
        try {
          cache.at = Date.now() + 60000;
          const r = await exec("gh", ["pr", "list", "-R", group.github, "--author", "@me", "--state", "open", "--limit", "1000", "--json", "number,headRefName,title,url,statusCheckRollup,reviewDecision"], { cwd });
          if (r.code !== 0) throw new Error("PRs unavailable");
          cache.list = JSON.parse(r.stdout).map(p => ({ number: p.number, branch: p.headRefName, title: p.title, url: p.url, ci: ciRollup(p.statusCheckRollup), review: p.reviewDecision, folder: group.worktrees.find(w => w.branch === p.headRefName)?.folder ?? cwd }));
          const value = Object.fromEntries(Object.entries(this.prs).map(([repo, data]) => [repo, data.list]));
          if (JSON.stringify(value) !== JSON.stringify(shared("tui-spaces.prs"))) setShared("tui-spaces.prs", value);
        } catch { cache.at = Date.now() + 300000; }
        finally { cache.busy = false; }
      } catch { group.at = Date.now() + 300000; }
      finally { group.busy = false; cx.notify(); }
    });
  }

  pr(g) {
    const repo = this.groups[g?.repo]?.github;
    const pr = this.prs[repo]?.list.find(p => p.branch === g.branch);
    return pr ? { ...pr, repo } : null;
  }
}
