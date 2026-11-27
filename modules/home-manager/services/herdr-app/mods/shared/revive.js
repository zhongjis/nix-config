// Reviving a finished agent terminal (a hibernated orchestrator worker, or any finished one with a resume line): one
// path for the Agents panel and the sub-agents popup. Pure: `hc` is passed in, so node tests run it.
//
// The launch contract comes from the finished terminal itself (`hc get <address> --json`), as the orchestrator skill's
// start-worker.sh made it: the argv's whole `env K=V…` prefix (PATH with the agent shims, the bead identity, values
// with spaces too), its name, cwd and parent, its notify and outlive-parent settings, and every label except the
// runtime ones (RUNTIME). The agent line is the `resume` label without its own `env` prefix. hibernate=ok comes back
// only when the old terminal had it, and never on Codex. The finished terminal is removed only after the new one
// started, so a failed start keeps it and its resume label.
// An orchestrated terminal (an `orch` label, or `orch-context` naming the skill's worker-context.sh) passes the skill's own launch
// checks first: `start-worker.sh <name> <cwd> <ORCH_BEAD> --kind <kind> --resume <session> --check`, beside that script,
// with the terminal's env. A reviewer whose review bead closed, a worker no longer assigned, or a reviewer whose checkout
// a worker is editing is refused there, and nothing starts. One whose bead, kind or session can't be read is refused.
//
// API
//   RUNTIME                      Labels a revive never copies (resume, resume.pid, hibernated, hibernate, settled,
//                                snoozed, orch.in, where, herdr.*).
//   envOf(argv)                  The `K=V` words after a leading `env` (or bare leading assignments), as given.
//   agentLine(resume)            A resume label's agent words, without its `env K=V…` prefix.
//   isCodex(k, line)             Whether the terminal runs Codex (its status app, or the agent line's program).
//   resumeOf(line)               The agent line's start-worker.sh kind and session ({ kind, session }) | null.
//   plan(k, { parentLive })      -> { args, check } (the `hc run` arguments; check: { argv } of the env + start-worker.sh
//                                --check run, for an orchestrated terminal, else null) | { error }: k is `hc get --json`
//                                of the finished terminal.
//   revive(address, { hc, exec, parentLive })
//                                -> { ok: true, address, warning? } | { ok: false, error }. parentLive(address) says
//                                whether a terminal is live, for `--parent`; exec(cmd, args) runs the check.

export const RUNTIME = /^(resume|resume\.pid|hibernated|hibernate|settled|snoozed|orch\.in|where)$|^herdr\./;
const ASSIGN = /^[A-Za-z_][A-Za-z0-9_]*=/;

export function envOf(argv) {
  const words = (argv ?? []).map(String);
  let at = /(^|\/)env$/.test(words[0] ?? "") ? 1 : 0;
  const out = [];
  for (; at < words.length && ASSIGN.test(words[at]); at++) out.push(words[at]);
  return out;
}

export function agentLine(resume) {
  const words = String(resume ?? "").trim().split(/\s+/).filter(Boolean);
  let at = /(^|\/)env$/.test(words[0] ?? "") ? 1 : 0;
  if (at) while (at < words.length && ASSIGN.test(words[at])) at++;
  return words.slice(at);
}

export const isCodex = (k, line) => k?.status?.app === "codex" || /(^|\/)codex$/.test(line?.[0] ?? "");

const SESSION = [
  ["claude", /^--resume$/], ["pi", /^--session$/], ["codex", /^resume$/],
];
export function resumeOf(line) {
  const prog = String(line?.[0] ?? "").split("/").pop();
  for (const [kind, flag] of SESSION) {
    if (prog !== kind) continue;
    const at = line.findIndex((w) => flag.test(w));
    return at > 0 && line[at + 1] ? { kind, session: line[at + 1] } : null;
  }
  const eq = { agy: "--conversation=", copilot: "--resume=" }[prog];
  const word = eq && line.find((w) => w.startsWith(eq));
  return word ? { kind: prog, session: word.slice(eq.length) } : null;
}

export function plan(k, { parentLive = () => false } = {}) {
  if (!k || typeof k !== "object") return { error: "The terminal is gone." };
  if ((k.state ?? "live") === "live") return { error: "It is still running." };
  const labels = k.labels ?? {};
  const line = agentLine(labels.resume);
  if (!line.length) return { error: "It has no resume line." };
  if (!k.cwd) return { error: "Its folder is unknown." };
  // The old argv's env carries PATH (the agent shims) and identity values whole; a terminal recovered as a shell
  // has none, so the resume label's own prefix is the fallback.
  const fromArgv = envOf(k.argv);
  const env = fromArgv.length ? fromArgv : envOf(String(labels.resume).trim().split(/\s+/));
  const args = ["run", "--bg", "--json", "--cwd", k.cwd];
  if (k.name) args.push("--name", k.name);
  if (k.parent && parentLive(k.parent)) args.push("--parent", k.parent);
  if (k.die_with_parent !== true) args.push("--outlive-parent");
  if (k.notify === false) args.push("--no-notify");
  for (const [key, value] of Object.entries(labels)) if (!RUNTIME.test(key)) args.push("--label", `${key}=${value}`);
  if (labels.hibernate === "ok" && !isCodex(k, line)) args.push("--label", "hibernate=ok");
  args.push("--", ...(env.length ? ["env", ...env] : []), ...line);
  // Orchestrated (an `orch` or `orch-context` label): the skill's launch checks, as start-worker.sh runs them for the
  // orchestrator. Without the skill's script to run them, it isn't revived here.
  const context = String(labels["orch-context"] ?? "");
  if (!context && !labels.orch) return { args, check: null };
  const bead = env.find((x) => x.startsWith("ORCH_BEAD="))?.slice("ORCH_BEAD=".length);
  const resume = resumeOf(line);
  if (!/\/worker-context\.sh$/.test(context) || !bead || !resume || !k.name) {
    return { error: "It belongs to an orchestrator, and its launch checks can't be run (no bead, session or skill script)." };
  }
  const script = context.replace(/worker-context\.sh$/, "start-worker.sh");
  return { args, check: { argv: [...env, script, k.name, k.cwd, bead, "--kind", resume.kind, "--resume", resume.session, "--check"] } };
}

const why = (r, what) => String(r?.stderr ?? "").trim() || `${what} exited ${r?.code ?? "?"}`;

export async function revive(address, { hc, exec, parentLive }) {
  const got = await hc(["get", address, "--json"]).catch((e) => ({ code: 1, stdout: "", stderr: String(e) }));
  if (got.code !== 0) return { ok: false, error: why(got, "hc get") };
  let k;
  try { k = JSON.parse(got.stdout); } catch { return { ok: false, error: "hc get gave no terminal." }; }
  const p = plan(k, { parentLive });
  if (p.error) return { ok: false, error: p.error };
  if (p.check) {
    const c = await exec("/usr/bin/env", p.check.argv).catch((e) => ({ code: 1, stdout: "", stderr: String(e) }));
    if (c.code !== 0) return { ok: false, error: `The orchestration checks refused it: ${why(c, "start-worker.sh --check").split("\n")[0]}` };
  }
  const res = await hc(p.args).catch((e) => ({ code: 1, stdout: "", stderr: String(e) }));
  if (res.code !== 0) return { ok: false, error: why(res, "hc run") };
  let started = null;
  try { started = JSON.parse(res.stdout)?.address ?? null; } catch {}
  if (!started) return { ok: false, error: "hc run started it but gave no address; the old terminal was kept." };
  const rm = await hc(["rm", address]).catch((e) => ({ code: 1, stdout: "", stderr: String(e) }));
  return rm.code === 0 ? { ok: true, address: started } : { ok: true, address: started, warning: why(rm, "hc rm") };
}
