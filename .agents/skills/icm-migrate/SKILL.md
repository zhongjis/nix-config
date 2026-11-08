---
name: icm-migrate
description: Bring a host's icm memory store to the tuned setup framework-16 runs (lighter embedding model, sparser extraction, daily prune, stale-memory cleanup, compaction).
disable-model-invocation: true
---

# icm migrate

Bring one host's icm to the setup `hosts/framework-16/home.nix` already runs. That host's `programs.icm.*` block is the reference configuration; copy it, adapting only what the platform forces.

Outcome: the host's database records `intfloat/multilingual-e5-base`, every remaining memory has an embedding, stale never-recalled context is gone, the file is compacted, a daily prune is scheduled, and recall answers from the daemon or CLI.

## Decision boundary

- **Inside**: read-only inspection (`icm stats`, `icm config`, read-only SQLite queries), editing `hosts/<host>/home.nix`, `nh home switch .`, `icm --no-embeddings backup`, and `icm embed --migrate` once the user has paused agents. The backup makes the migration recoverable.
- **Outside**: the stale-memory delete. Show the user the rule and the exact row count, and run it only after they confirm that count. Restoring a backup also waits for the user.
- Agents must be paused before the migration starts. Ask the user to pause them, and tell the user when they can start them again.

## Steps

1. **Preflight.** On the target host, record: icm version (`icm --version`), database path and current model (`icm stats` prints a warning naming the recorded model when config and database disagree; `icm_metadata.embedding_model` holds it), memory count, how many have `access_count = 0`, and free disk (the backup is roughly the database size). Done when every value is written down.
   - The behaviour below was verified against icm **0.11.5**. On another version, re-check each gotcha in [Reference](#reference) against that tag's source before relying on it.
2. **Configure.** Add to `hosts/<host>/home.nix`, mirroring framework-16:
   - `programs.icm.settings.embeddings.model = "intfloat/multilingual-e5-base";`
   - `programs.icm.settings.extraction.extract_every = 12;`
   - a daily prune running `icm --no-embeddings prune --threshold 0.3`: a `systemd.user` service plus timer on Linux (copy framework-16's), a Home Manager `launchd.agents` entry with a daily `StartCalendarInterval` on Darwin.
   - Run `nh home switch .`. Done when `~/.config/icm/config.toml` (Darwin: `~/Library/Application Support/dev.icm.icm/config.toml`) shows both settings and the prune schedule is listed (`systemctl --user list-timers icm-prune.timer`, or `launchctl list | grep icm`).
3. **Stop icm.** With agents paused, stop every other process on the database: `systemctl --user stop icm.service` on a Linux daemon host, and any MCP or `icm serve` process `pgrep -a icm` still shows. Done when `pgrep -a icm` is empty.
4. **Back up.** `icm --no-embeddings backup`. Done when it prints the backup path and that file exists.
5. **Clean up stale memories** (needs the user's confirmation of the count). Count first, read-only:
   ```sql
   SELECT count(*) FROM memories
    WHERE topic LIKE 'context-%' AND access_count = 0
      AND importance IN ('medium','low')
      AND created_at < datetime('now','-7 days');
   ```
   After confirmation, run the delete as one transaction with `sqlite3 -bail`, loading `vec0` first (see Reference): build a temp table of those ids, then delete them from `vec_memories`, then from `memories` (the `memories_ad` trigger cleans the full-text index), then strip their ids from other rows' `related_ids` with `json_each`, mirroring `crates/icm-store/src/store/memory.rs`'s bulk delete. Done when the deleted count equals the confirmed count and `(SELECT count(*) FROM memories_fts) - (SELECT count(*) FROM memories)` is 0.
   - Clean up before migrating: every deleted memory is one the migration no longer embeds. On framework-16 this removed 17,221 of 37,848 memories and cut the remaining migration by about 40 minutes.
6. **Migrate.** `icm embed --migrate`, in the background. It backs up, discards the stored vectors, recreates the index at 768 dimensions, and re-embeds everything; expect a few hundred memories per minute on CPU. If it stops, a plain `icm embed` resumes. Done when it exits 0 and `icm embed` prints `All memories already have embeddings.`
7. **Compact.** With icm still stopped: `sqlite3 <db> ".load <vec0>" "PRAGMA wal_checkpoint(TRUNCATE);" "VACUUM;" "PRAGMA quick_check;"`. Done when `quick_check` prints `ok`. (framework-16 went from 1.01 GB to 201 MB.)
8. **Restart and verify.** Start the daemon (Linux), then confirm: `icm stats` has no model warning, `icm_metadata` shows `intfloat/multilingual-e5-base` / `768`, a recall for a topic you know exists returns it (daemon: `POST http://127.0.0.1:9876/recall?format=json` with `{"query": "...", "limit": 5}`), and `icm --no-embeddings prune --threshold 0.3 --dry-run` runs. Done when all four pass.

Handoff: tell the user the before/after memory count, database size, and the backup path, which checks passed, and that they can start their agents again.

## Reference

Gotchas that no config file or `--help` output reveals (icm 0.11.5):

- **The stored model wins.** Changing `[embeddings] model` alone does nothing; icm keeps using the model recorded in the database until `icm embed --migrate` runs. The migration requires every other icm process on that database to be stopped first, or they keep embedding with the old model.
- **Ignored settings.** `[extraction] min_score`, `[extraction] max_facts` (hardcoded to 2.0 and 20 in `extract.rs`), and `[memory] prune_threshold` (prune uses its `--threshold` flag, default 0.1) have no effect. `extract_every` is the only working extraction-volume setting; the Claude Code post hook and the Pi icm extension's native mode both read it, and running Pi sessions pick it up at their next start.
- **Decay is automatic, pruning is not.** Weights decay by `0.95^days` on the first recall each day (`maintenance.rs`, `maybe_auto_decay`); nothing prunes unless `icm prune` runs. Prune never deletes `high` or `critical`. With no recalls, a medium memory falls below 0.3 after about 23 days.
- **`--no-embeddings` is a global flag**: place it before the subcommand (`icm --no-embeddings prune ...`) so maintenance commands skip loading the model.
- **`vec0` for raw SQL.** `vec_memories` is a sqlite-vec virtual table, so `sqlite3` must `.load` the `vec0` extension from `nixpkgs#sqlite-vec` before touching it or running `VACUUM`. Match its version to the `sqlite-vec` entry in icm's `Cargo.lock` for that tag (0.1.9 for icm 0.11.5).
- **Concurrency.** icm opens SQLite in WAL mode with a 30 s busy timeout, so `prune` and read-only queries are safe beside a running daemon or migration, and the migration skips rows deleted under it. The delete in step 5 still waits for paused agents, because new memories arriving mid-delete would muddy the confirmed count.
- **Why e5-base.** It costs about 4× less CPU than `multilingual-e5-large` and keeps Chinese support. On 50 real prompts, graded blind, it returned about 8% fewer relevant top-5 results; `multilingual-e5-small` is the next step down if heat still matters more than recall.
- **Darwin.** The `programs.icm.daemon` HTTP service is Linux-only, so a Darwin host has no daemon to stop or restart; recall runs through the CLI and MCP. Its database defaults to `~/Library/Application Support/dev.icm.icm/memories.db`.
