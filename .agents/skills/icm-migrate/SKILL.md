---
name: icm-migrate
description: Migrate a host's icm memory database to the intfloat/multilingual-e5-base embedding model, with optional stale-memory cleanup first and compaction after.
disable-model-invocation: true
---

# icm migrate

Move one host's icm database from its recorded embedding model (the `Qdrant/multilingual-e5-large-onnx` default) to `intfloat/multilingual-e5-base`, the model framework-16 now runs.

Outcome: the database records `intfloat/multilingual-e5-base` at 768 dimensions, every memory has an embedding, the file is compacted, and recall answers.

## Decision boundary

- **Inside**: read-only inspection (`icm stats`, read-only SQLite queries), editing `hosts/<host>/home.nix`, `nh home switch .`, `icm --no-embeddings backup`, stopping and restarting icm, `icm embed --migrate`, and `VACUUM`. The backup in step 4 makes the migration recoverable.
- **Outside**: the stale-memory delete. Show the user the rule and the exact row count, and run it only after they confirm that count. Restoring a backup also waits for the user.
- Agents must be paused while icm is stopped. Ask the user to pause them before step 3, and tell the user when they can start them again.

## Steps

1. **Preflight.** On the target host, record: icm version (`icm --version`), database path, recorded model (`icm_metadata.embedding_model`), memory count, how many have `access_count = 0`, and free disk (the backup is roughly the database size). Done when every value is written down.
   - This procedure was verified against icm **0.11.5**. On another version, re-check each gotcha in [Reference](#reference) against that tag's source before relying on it.
2. **Request the model.** Set `programs.icm.settings.embeddings.model = "intfloat/multilingual-e5-base";` in `hosts/<host>/home.nix` (framework-16 has the same line) and run `nh home switch .`. Done when `icm stats` prints the warning that the database's recorded model differs from the configuration.
3. **Stop icm.** With agents paused, stop every icm process on the database: `systemctl --user stop icm.service` on a Linux daemon host, plus any MCP or `icm serve` process `pgrep -a icm` still shows. Done when `pgrep -a icm` is empty.
4. **Back up.** `icm --no-embeddings backup`. Done when it prints the backup path and that file exists.
5. **Clean up stale memories** (optional; needs the user's confirmation of the count). Every memory deleted here is one the migration no longer embeds. On framework-16 this removed 17,221 of 37,848 memories and cut about 40 minutes from the migration. Count first, read-only:
   ```sql
   SELECT count(*) FROM memories
    WHERE topic LIKE 'context-%' AND access_count = 0
      AND importance IN ('medium','low')
      AND created_at < datetime('now','-7 days');
   ```
   After confirmation, run the delete as one transaction with `sqlite3 -bail`, loading `vec0` first (see Reference): build a temp table of those ids, then delete them from `vec_memories`, then from `memories` (the `memories_ad` trigger cleans the full-text index), then strip their ids from other rows' `related_ids` with `json_each`, mirroring the bulk delete in `crates/icm-store/src/store/memory.rs`. Done when the deleted count equals the confirmed count and `(SELECT count(*) FROM memories_fts) - (SELECT count(*) FROM memories)` is 0.
6. **Migrate.** `icm embed --migrate`, in the background. It backs up, discards the stored vectors, recreates the index at 768 dimensions, and re-embeds every memory; expect a few hundred memories per minute on CPU. If it stops, a plain `icm embed` resumes. Done when it exits 0 and `icm embed` prints `All memories already have embeddings.`
7. **Compact.** With icm still stopped: `sqlite3 <db> ".load <vec0>" "PRAGMA wal_checkpoint(TRUNCATE);" "VACUUM;" "PRAGMA quick_check;"`. Done when `quick_check` prints `ok`. (framework-16 went from 1.01 GB to 201 MB.)
8. **Restart and verify.** Start the daemon (Linux), then confirm: `icm stats` prints no model warning, `icm_metadata` shows `intfloat/multilingual-e5-base` / `768`, and a recall for a topic you know exists returns it (daemon: `POST http://127.0.0.1:9876/recall?format=json` with `{"query": "...", "limit": 5}`; Darwin: `icm recall "<query>"`). Done when all three pass.

Handoff: tell the user the before/after memory count and database size, the backup path, which checks passed, and that they can start their agents again.

## Reference

Gotchas that no config file or `--help` output reveals (icm 0.11.5):

- **The stored model wins.** Changing `[embeddings] model` alone does nothing; icm keeps using the model recorded in the database until `icm embed --migrate` runs. Any icm process still running during the migration keeps embedding with the old model until it restarts.
- **`--no-embeddings` is a global flag**: place it before the subcommand (`icm --no-embeddings backup`) so maintenance commands skip loading the model.
- **`vec0` for raw SQL.** `vec_memories` is a sqlite-vec virtual table, so `sqlite3` must `.load` the `vec0` extension from `nixpkgs#sqlite-vec` before deleting from it or running `VACUUM`. Match its version to the `sqlite-vec` entry in icm's `Cargo.lock` for that tag (0.1.9 for icm 0.11.5).
- **Concurrency.** icm opens SQLite in WAL mode with a 30 s busy timeout, and the migration skips rows deleted under it. The delete in step 5 still waits for paused agents, because new memories arriving mid-delete would change the confirmed count.
- **Why e5-base.** It costs about 4× less CPU than `multilingual-e5-large` and keeps Chinese support. On 50 real prompts, graded blind, it returned about 8% fewer relevant top-5 results.
- **Darwin.** The `programs.icm.daemon` HTTP service is Linux-only, so a Darwin host has no daemon to stop or restart; recall runs through the CLI and MCP. Its database defaults to `~/Library/Application Support/dev.icm.icm/memories.db`.
