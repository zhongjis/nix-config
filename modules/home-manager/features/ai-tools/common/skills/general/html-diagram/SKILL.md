---
name: html-diagram
description: Create a self-contained HTML architecture/infra diagram with layout-first SVG, light prose, animated/highlighted flows, and no overlaps or ambiguous arrows.
disable-model-invocation: true
---

# HTML Diagram

Create a self-contained HTML file that makes an architecture, infrastructure, or system flow click fast.
The output should be mostly visual: full-screen diagram, sparse labels, highlighted flows, and a small detail panel.

## Workflow

1. Read `references/architecture-example.html` for the shell pattern: full-screen SVG stage, flow chips, clickable nodes, lit request paths, side detail panel, and dark mode.
2. Read at most one relevant file from `references/html-effectiveness/` when you need a style cue.
   Do not scan the whole reference gallery unless the user explicitly asks; broad reference reading makes generation slow.
3. Write a graph spec before HTML: title, audience, zones/groups, nodes, edges, flow states, and any sequence chips.
   If the graph feels dense, split it into scenes/lanes before drawing.
4. Choose the renderer:
   - Default for architecture/infra/pipeline diagrams: D2-generated SVG, embedded in the HTML shell.
   - Simple flowcharts: Mermaid is acceptable when layout control is not critical.
   - Hand-authored SVG: only for tiny custom diagrams (about 8 nodes or fewer) or decorative elements. Do not hand-place dense architecture graphs.
   - If D2 is not available, fall back explicitly: Mermaid for simple flowcharts, hand-authored SVG only for tiny/decorative pieces.
     Do not pretend a renderer was run.
5. Let the renderer own layout. Let the HTML shell own interaction, highlighting, animation, theme, and details.
6. For D2 output, keep the D2 graph text as the layout source.
   If layout changes are needed, update the graph and rerender.
   Post-process generated SVG only for ids/classes/styles used by the HTML shell.
   Do not hand-edit generated SVG coordinates.

## Artifact contract

- Produce one standalone `.html` file.
- It must render offline without network access, CDN assets, or a build step.
  Inline generated SVG, CSS, and JS in the HTML file.
- Keep prose light. Put explanation in node details or a side dock, not over the diagram.
- Keep diagram styling class-based.
  Use stable node/edge IDs or `data-*` attributes so chips can light up exact paths.
- Preserve interaction when useful: flow chips, clickable nodes, selected details, and `.lit` classes.
- Preserve animation when useful: CSS stroke-dashoffset/path pulse on lit edges, with `prefers-reduced-motion` support.
- Always include dark mode:
  - CSS variables on `:root` / `html.dark`.
  - Small theme toggle.
  - `localStorage` persistence.
  - Apply-before-paint script in `<head>` defaulting to `prefers-color-scheme`.
  - SVG styled through CSS variables/classes, not hard-coded SVG colors.

## No-overlap rules

- Nodes, labels, badges, and cards must not intersect. If space is tight, increase the viewBox, add scroll/pan, split scenes, or move details into a dock.
- Arrowheads must visibly terminate at the source/target node boundary, not in empty space or through node text.
- Edge labels must sit on clear whitespace and must not cross unrelated nodes.
- Use short labels. Wrap or split long text into details so node text never drives overlap.
- Route edges to minimize crossings; prefer orthogonal or separated paths over diagonal lines through content.
- Keep a reserved margin around zones and at least one node-height of vertical separation between parallel lanes.
- Put detail cards outside the SVG stage or in a reserved dock. Never float cards over important diagram content.
- For large graphs, prefer multiple chips/scenes over one crowded canvas.

## Final QA

Before reporting done, check the artifact for:
Open the file in a browser or capture a screenshot; do not rely only on static checks.
If you cannot run browser/screenshot QA, say visual QA is not verified; do not claim it passed.
- No node overlap.
- No label clipping.
- No box/card overlap.
- Clear arrow starts/ends.
- Readable dark and light modes.
- Each flow chip highlights the intended nodes and edges.

If a visual check finds overlap, fix layout first. Do not accept a crowded diagram.
