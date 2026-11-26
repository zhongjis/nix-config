// Live beads for the fleet view, read-only: bd list / bd comments, never a write.
// Per orchestrator address A: its open session epics, each epic's tasks, each task's event comments.
// The app's own environment can hold a stale BEADS_DIR, so bd runs with the login shell's (beadsDir()).

import { exec } from "herdr";
import { eventsOf } from "./model.js";

export class BeadsError extends Error {}

/** @param {unknown} x @returns {Record<string, unknown>} */
const obj = (x) => (x && typeof x === "object" ? Object.fromEntries(Object.entries(x)) : {});
/** @param {unknown} x */
const str = (x) => (typeof x === "string" ? x : undefined);

/** bd's metadata: an object, or the same as a JSON string. Values read as text. @param {unknown} x */
function metadata(x) {
  let md = x;
  if (typeof x === "string") {
    try { md = JSON.parse(x); } catch (e) { if (e instanceof SyntaxError) md = {}; else throw e; }
  }
  return Object.fromEntries(Object.entries(obj(md)).map(([k, v]) => [k, String(v)]));
}

/** @param {unknown} x @returns {import("./model.js").Bead} */
const toBead = (x) => {
  const o = obj(x);
  return { id: str(o.id) ?? "", title: str(o.title), status: str(o.status), assignee: str(o.assignee), metadata: metadata(o.metadata) };
};
/** @param {unknown} x @returns {import("./model.js").Comment} */
const toComment = (x) => { const o = obj(x); return { text: str(o.text), created_at: str(o.created_at) }; };

/** The login shell's BEADS_DIR ("" when it sets none, or the shell can't say). */
export async function beadsDir() {
  const r = await exec("zsh", ["-lc", 'printf %s "$BEADS_DIR"'], { timeout: 10000 });
  return r.code === 0 ? r.stdout.trim() : "";
}

/**
 * One bd call, parsed as the JSON list it promises. bd's warnings go to stderr; the first other line names a failure.
 * `dir`: the BEADS_DIR to run with (env sets it: exec takes no environment); "" runs bd as the app's env has it.
 * @param {string} dir
 * @param {string[]} args
 * @returns {Promise<unknown[]>}
 */
async function bdList(dir, args) {
  const argv = [...args, "--json"];
  const r = dir ? await exec("/usr/bin/env", [`BEADS_DIR=${dir}`, "bd", ...argv], { timeout: 15000 })
    : await exec("bd", argv, { timeout: 15000 });
  if (r.code !== 0) {
    const why = r.stderr.split("\n").map((l) => l.trim()).find((l) => l && !/^(warning:|Fix:|Or:|Hint:)/.test(l));
    throw new BeadsError(why ?? `bd exited ${r.code}`);
  }
  const out = JSON.parse(r.stdout.trim() || "[]");
  if (!Array.isArray(out)) throw new BeadsError("bd answered without a list");
  return out;
}

/**
 * @param {string} dir
 * @param {import("./model.js").Bead} epic
 * @returns {Promise<import("./model.js").Epic>}
 */
async function epicWithTasks(dir, epic) {
  const beads = (await bdList(dir, ["list", "--parent", epic.id, "--all", "--limit", "0"])).map(toBead);
  const tasks = await Promise.all(beads.map(async (bead) => ({ bead, events: eventsOf((await bdList(dir, ["comments", bead.id])).map(toComment)) })));
  return { epic, tasks };
}

/**
 * Map<orchestrator address, epics[]>: every orchestrator asked has an entry, empty when it has no open epic.
 * Rejects with BeadsError (or exec's own error) when bd can't answer.
 * @param {string[]} orchestrators
 * @param {string} dir
 */
export async function loadLive(orchestrators, dir) {
  /** @type {Map<string, import("./model.js").Epic[]>} */
  const byOrch = new Map();
  for (const address of orchestrators) {
    const epics = (await bdList(dir, ["list", "--type", "epic", "--metadata-field", `session=${address}`,
      "--status", "open,in_progress,blocked,deferred", "--limit", "0"])).map(toBead);
    byOrch.set(address, await Promise.all(epics.map((e) => epicWithTasks(dir, e))));
  }
  return byOrch;
}
