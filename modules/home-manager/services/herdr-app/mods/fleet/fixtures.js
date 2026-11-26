// A made-up epic for the fleet view when live beads aren't wanted (fleet.fixture; "Sample data" in the header).
// One epic, four tasks, one per stage: merged, PR in review, blocked on the person, queued with no worker.
// Timestamps count back from `now` so ages read sensibly; terminal addresses are fake (tfx*), so every task
// draws as a bead card of its own. Comments are parsed as live ones are (eventsOf).

import { eventsOf } from "./model.js";

/** @param {number} now @param {number} minutesAgo @param {string} text */
const ev = (now, minutesAgo, text) => ({ text, created_at: new Date(now - minutesAgo * 60000).toISOString() });

/**
 * @param {number} now
 * @returns {import("./model.js").Epic[]}
 */
export function fixtureEpics(now) {
  return [{
    epic: { id: "fx-1", title: "orch: bd adoption", status: "in_progress", metadata: { slug: "bd adoption" } },
    tasks: [
      {
        bead: { id: "fx-1.1", title: "Vendor the beads skill into the catalog", status: "closed",
          metadata: { key: "vendor-beads-skill", review_round: "1", pr_url: "github.com/acme/agent-skills/pull/412",
            head_sha: "4be1c09", merged_sha: "9f3d2a7c1e0b8a6f5d4c3b2a1908f7e6d5c4b3a2" } },
        events: eventsOf([
          ev(now, 190, "event=dispatched agent=w-vendor-beads-skill terminal=tfx1"),
          ev(now, 120, "event=ready pr=412"),
          ev(now, 95, "event=dispatched agent=r-vendor-beads-skill terminal=tfx2 round=1"),
          ev(now, 40, "event=merged merged_sha=9f3d2a7c1e0b8a6f5d4c3b2a1908f7e6d5c4b3a2"),
        ]),
      },
      {
        bead: { id: "fx-1.2", title: "Switch the orchestration copy to bd events", status: "in_progress",
          metadata: { key: "orch-copy-bd-events", review_round: "1", pr_url: "github.com/acme/agent-skills/pull/415",
            head_sha: "c0ffee1" } },
        events: eventsOf([
          ev(now, 150, "event=dispatched agent=w-orch-copy-bd-events terminal=tfx3"),
          ev(now, 60, "event=ready pr=415"),
          ev(now, 22, "event=dispatched agent=r-orch-copy-bd-events terminal=tfx4 round=1"),
        ]),
      },
      {
        bead: { id: "fx-1.3", title: "Pick the retention window for closed beads", status: "blocked",
          metadata: { key: "bead-retention", blocked_reason: "needs-user" } },
        events: eventsOf([
          ev(now, 80, "event=dispatched agent=w-bead-retention terminal=tfx5"),
          ev(now, 12, "event=blocked reason=needs-user\n\nKeep closed beads 30 or 90 days? 90 doubles the db size."),
        ]),
      },
      {
        bead: { id: "fx-1.4", title: "pi-config: read todos from bd", status: "open",
          metadata: { key: "pi-config-bd-todos" } },
        events: eventsOf([ev(now, 5, "event=queued after=fx-1.2")]),
      },
    ],
  }];
}
