// Run: node modules/home-manager/services/herdr-app/tests/keys-manifest.mjs  (needs jq on PATH)
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync, existsSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const script = join(dirname(fileURLToPath(import.meta.url)), "../../../../../custom-home-manager-options/herdr-app/merge-keys.sh");
const dir = mkdtempSync(join(tmpdir(), "keys-manifest-"));
const live = join(dir, "keys.json");
const manifest = join(dir, "state", "managed-keys.json");
const nixFile = join(dir, "nix.json");
const write = (p, v) => writeFileSync(p, typeof v === "string" ? v : JSON.stringify(v));
const read = (p) => JSON.parse(readFileSync(p, "utf8"));
const run = (nix) => {
  write(nixFile, nix);
  const r = spawnSync("bash", [script, "jq", live, manifest, nixFile], { encoding: "utf8" });
  assert.equal(r.status, 0, r.stderr);
  return r;
};
const reset = () => { for (const p of [live, join(dir, "state")]) rmSync(p, { recursive: true, force: true }); };

try {
  // pruned when Nix drops it; a user's rebind stays; an emptied section goes
  reset();
  run({ global: { a: "x", b: "y" }, "layout:p": { c: "z" } });
  assert.deepEqual(read(live), { global: { a: "x", b: "y" }, "layout:p": { c: "z" } });
  const live1 = read(live);
  live1.global.b = "mine";
  live1.user = {};
  write(live, live1);
  run({ global: { a: "x" } });
  assert.deepEqual(read(live), { global: { a: "x", b: "mine" }, user: {} }, "rebind kept, emptied section removed, user's own empty section kept");
  assert.deepEqual(read(manifest).managed, [["global", "a", "x"]]);

  // failed prune: nothing written, manifest unchanged; the next run retries
  reset();
  run({ global: { a: "x" }, s: { k: "v" } });
  const before = readFileSync(manifest, "utf8");
  write(live, "{ not json");
  const r = run({ global: { a: "x" } });
  assert.match(r.stderr, /not updated/);
  assert.equal(readFileSync(live, "utf8"), "{ not json");
  assert.equal(readFileSync(manifest, "utf8"), before);
  write(live, { global: { a: "x" }, s: { k: "v" } });
  run({ global: { a: "x" } });
  assert.deepEqual(read(live), { global: { a: "x" } });

  // empty Nix keys with a manifest still prune the last binding and update the manifest
  run({});
  assert.deepEqual(read(live), {});
  assert.deepEqual(read(manifest).managed, []);

  // old list-format manifest (round 1): its entries carry no value, so a key it lists may be a user's rebind and is
  // kept; the new format replaces it
  reset();
  write(live, { global: { old: "x", keep: "k" }, gone: { z: "1" } });
  write(join(dir, "state"), "");
  rmSync(join(dir, "state"), { recursive: true, force: true });
  spawnSync("mkdir", ["-p", dirname(manifest)]);
  write(manifest, [["global", "old"], ["gone", "z"]]);
  run({ global: { keep: "k" } });
  assert.deepEqual(read(live), { global: { old: "x", keep: "k" }, gone: { z: "1" } });
  assert.deepEqual(read(manifest), { managed: [["global", "keep", "k"]] });
  assert.ok(!existsSync(`${manifest}.new`), "no staged manifest left behind");
  // ...while a legacy entry with its known value still prunes under an old list manifest
  reset();
  spawnSync("mkdir", ["-p", dirname(manifest)]);
  write(manifest, [["mod:fleet", "ctrl-shift-a"]]);
  write(live, { "mod:fleet": { "ctrl-shift-a": "fleet.toggle" }, global: { a: "x" } });
  run({ global: { a: "x" } });
  assert.deepEqual(read(live), { global: { a: "x" } });

  // a manifest that can't be staged changes nothing (keys.json included)
  reset();
  run({ global: { a: "x" } });
  spawnSync("chmod", ["a-w", dirname(manifest)]);
  const unstaged = run({ global: { a: "y" } });
  spawnSync("chmod", ["u+w", dirname(manifest)]);
  assert.match(unstaged.stderr, /not updated/);
  assert.deepEqual(read(live), { global: { a: "x" } });

  // legacy sections: pruned when unchanged, kept when rebound
  reset();
  write(live, {
    "mod:fleet": { "ctrl-shift-a": "fleet.toggle" },
    "layout:herdr-fleet": { "ctrl-shift-s": "mine", "ctrl-shift-a": { command: "layout.select", args: { stack: "work-switch", child: "fleet" } } },
    "layout:herdr-tui": { "ctrl-shift-s": "tui-focus.settle" },
    "layout:herdr-t3": { x: "y" },
  });
  run({ global: { a: "x" } });
  assert.deepEqual(read(live), { "layout:herdr-fleet": { "ctrl-shift-s": "mine" }, "layout:herdr-t3": { x: "y" }, global: { a: "x" } });
  assert.ok(existsSync(manifest));
  console.log("keys-manifest: ok");
} finally {
  rmSync(dir, { recursive: true, force: true });
}
