---
name: html-diagram
description: Create a self-contained HTML architecture/infra diagram with layout-first SVG, light prose, animated/highlighted flows, and no overlaps or ambiguous arrows.
disable-model-invocation: true
---

# HTML Diagram

Create a self-contained HTML file that makes an architecture, infrastructure, or system flow click fast.
The output should be mostly visual: full-screen diagram, sparse labels, highlighted flows, and a small detail panel.

## Workflow

1. Read `references/architecture-example.html` only when you need to inspect the shell pattern.
2. Read at most one relevant file from `references/html-effectiveness/` when you need a style cue.
   Do not scan the whole reference gallery unless the user explicitly asks; broad reference reading makes generation slow.
3. Write a graph spec before HTML: title, audience, zones/groups, nodes, edges, flow states, and any sequence chips.
   If the graph feels dense, split it into scenes/lanes before drawing.
4. Choose the renderer:
   - Default for dense architecture/infra/pipeline diagrams: D2-generated SVG with ELK layout when available, embedded in the HTML shell.
   - Render D2 with tight framing: prefer `d2 --layout=elk --pad 16` (or the smallest readable pad), avoid `--center`, and rerender instead of accepting a huge blank viewBox.
   - Simple flowcharts: Mermaid is acceptable when layout control is not critical; use Mermaid ELK for larger Mermaid graphs when available.
   - Graphviz/DOT is acceptable for hierarchical dependency diagrams when you need explicit `ranksep`, `nodesep`, `margin=0`, or `ratio=compress` controls.
   - Hand-authored SVG: only for tiny custom diagrams (about 8 nodes or fewer) or decorative elements. Do not hand-place dense architecture graphs.
   - If the intended renderer is not available, fall back explicitly and say which renderer actually produced the diagram.
   - Do not pretend a renderer was run.
5. Let the renderer own layout. Let the reusable wrapper own the standard HTML shell, interaction, highlighting, animation, theme, and details.
6. For renderer output, keep the graph text as the layout source.
   If layout changes are needed, update the graph and rerender.
   Post-process generated SVG only for stable ids/classes/data attributes before wrapping.
   Do not hand-edit generated SVG coordinates.
7. Use `scripts/html-diagram-wrap.py` to create the standalone HTML shell instead of rewriting CSS/JS from scratch.
   Write a small JSON config with title, subtitle, flows, and details; pass the rendered SVG to the wrapper.


## Reusable wrapper

Use the bundled wrapper for normal architecture/infra/pipeline diagrams:

```bash
python <skill-dir>/scripts/html-diagram-wrap.py \
  --svg rendered.svg \
  --config diagram-config.json \
  --out diagram.html
```

Config shape:

```json
{
  "title": "System flow",
  "subtitle": "Current path vs target path",
  "flows": [
    {"id": "happy", "label": "Happy path", "targets": ["node-a", "edge-a-b"]}
  ],
  "details": {
    "node-a": {"title": "Node A", "body": "What this node does"}
  },
  "fitViewBox": true,
  "keyboardGraph": true
}
```

Prepare the SVG so important nodes/edges have stable `id` or `data-k` values that match flow targets. Keep each flow target list narrow enough that the active path is visually distinct; do not highlight half the graph for a single chip/node.
If you want an overview selected on load, make the first flow an explicit `all`/overview chip with empty targets; otherwise the wrapper starts undimmed until the user chooses a flow or node.
The wrapper auto-fits SVG viewBox to interactive graph content to reduce blank canvas; set `"fitViewBox": false` only when a diagram intentionally needs preserved outer margins or decorative zones.
Graph nodes are keyboard-focusable by default; set `"keyboardGraph": false` only when a very dense diagram would create too many tab stops.
Only hand-write the full HTML shell when the user asks for a custom shell that the wrapper cannot express.
## Artifact contract

- Produce one standalone `.html` file.
- It must render offline without network access, CDN assets, or a build step.
  Inline generated SVG, CSS, and JS in the HTML file.
- Keep prose light. Put explanation in node details or a side dock, not over the diagram.
- Keep diagram styling class-based.
  Use stable node/edge IDs or `data-*` attributes so chips can light up exact paths.
- Preserve interaction when useful: flow chips, clickable nodes, selected details, and `.lit` classes.
  Put `data-k`/`id` on the clickable graph group (`.node`, `.edge`, `.d2-node`, `.d2-edge`, `.d2-zone`) rather than only on inner text/paths, so node clicks highlight the intended element.
- Preserve animation when useful: CSS stroke-dashoffset/path pulse on lit edges, with `prefers-reduced-motion` support.
- Always include dark mode:
  - CSS variables on `:root` / `html.dark`.
  - Small theme toggle.
  - `localStorage` persistence.
  - Apply-before-paint script in `<head>` defaulting to `prefers-color-scheme`.
  - SVG styled through CSS variables/classes, not hard-coded SVG colors.

## No-overlap and no-wasted-space rules

- Nodes, labels, badges, and cards must not intersect. If space is tight, first trim renderer padding/viewBox and shorten labels; then add scroll/pan, split scenes, or move details into a dock.
- Large blank canvas is a defect. Keep the rendered diagram bounds tight around content; avoid centering small graphs inside huge SVG/viewBox space.
- Arrowheads must visibly terminate at the source/target node boundary, not in empty space or through node text.
- Edge labels must sit on clear whitespace and must not cross unrelated nodes.
- Use short labels. Wrap or split long text into details so node text never drives overlap.
- Route edges to minimize crossings; prefer orthogonal or separated paths over diagonal lines through content.
- Keep a reserved margin around zones and at least one node-height of vertical separation between parallel lanes.
- Put detail cards outside the SVG stage or in a reserved dock. Never float cards over important diagram content.
- For large graphs, prefer multiple chips/scenes over one crowded canvas.
- Active highlighting must be unmistakable: dim non-active nodes/edges, use a high-contrast accent distinct from base graph colors, and keep the active set small enough to understand.

## Final QA

Before reporting done, check the artifact for:
Open the file in a browser or capture a screenshot; do not rely only on static checks.
If you cannot run browser/screenshot QA, say visual QA is not verified; do not claim it passed.
- No node overlap.
- No label clipping.
- No box/card overlap.
- No excessive blank canvas around the graph.
- Clear arrow starts/ends.
- Readable dark and light modes.
- Each flow chip highlights the intended nodes and edges, with inactive graph elements visibly de-emphasized.
- Clicking a node or flow makes the active selection obvious even when the base graph already uses blue or similar colors.

If a visual check finds overlap, fix layout first. Do not accept a crowded diagram.
