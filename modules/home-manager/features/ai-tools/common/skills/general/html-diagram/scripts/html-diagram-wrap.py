#!/usr/bin/env python3
"""Wrap a rendered SVG in the standard html-diagram standalone shell.

Input config JSON shape:
{
  "title": "Diagram title",
  "subtitle": "Short context",
  "flows": [
    {"id": "happy", "label": "Happy path", "targets": ["node-a", "edge-a-b"]}
  ],
  "details": {
    "node-a": {"title": "Node A", "body": "What this node does."}
  }
}

Targets match SVG element id values first, then data-k values. The script does not
change SVG layout coordinates; update and rerender the graph source for layout fixes.
"""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
from typing import Any


CSS = """
:root {
  color-scheme: light;
  --bg: #f6f7fb;
  --panel: rgba(255, 255, 255, 0.92);
  --text: #0f172a;
  --muted: #64748b;
  --line: rgba(15, 23, 42, 0.14);
  --accent: #2563eb;
  --accent-soft: rgba(37, 99, 235, 0.16);
  --shadow: 0 22px 70px rgba(15, 23, 42, 0.16);
}
html.dark {
  color-scheme: dark;
  --bg: #080b14;
  --panel: rgba(15, 23, 42, 0.86);
  --text: #e5e7eb;
  --muted: #94a3b8;
  --line: rgba(226, 232, 240, 0.16);
  --accent: #60a5fa;
  --accent-soft: rgba(96, 165, 250, 0.18);
  --shadow: 0 22px 70px rgba(0, 0, 0, 0.38);
}
* { box-sizing: border-box; }
body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at 20% 0%, var(--accent-soft), transparent 34rem), var(--bg);
  color: var(--text);
  font: 14px/1.45 Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
.shell { min-height: 100vh; display: grid; grid-template-rows: auto 1fr; }
header {
  display: flex;
  gap: 1rem;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--line);
  backdrop-filter: blur(16px);
}
h1 { margin: 0; font-size: clamp(1.25rem, 2.2vw, 2rem); letter-spacing: -0.03em; }
.subtitle { margin: 0.25rem 0 0; color: var(--muted); max-width: 72ch; }
.actions { display: flex; gap: 0.5rem; flex-wrap: wrap; justify-content: flex-end; }
button {
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 0.5rem 0.75rem;
  color: var(--text);
  background: var(--panel);
  cursor: pointer;
}
button:hover, button.active { border-color: var(--accent); background: var(--accent-soft); }
main { display: grid; grid-template-columns: minmax(0, 1fr) min(360px, 34vw); min-height: 0; }
.stage { min-width: 0; overflow: auto; padding: 1rem; }
.stage svg { display: block; width: 100%; height: auto; min-width: 980px; }
aside {
  border-left: 1px solid var(--line);
  padding: 1rem;
  background: var(--panel);
  box-shadow: var(--shadow);
  overflow: auto;
}
.detail-title { margin: 0 0 0.5rem; font-size: 1rem; }
.detail-body { color: var(--muted); white-space: pre-wrap; }
.lit, .lit * { stroke: var(--accent) !important; }
.lit:not(text), .lit *:not(text) { filter: drop-shadow(0 0 10px var(--accent-soft)); }
.node.lit rect, [data-k].lit rect, rect.lit { fill: var(--accent-soft) !important; }
.edge.lit, path.lit, line.lit, polyline.lit { stroke-width: 3px !important; stroke-dasharray: 10 6; animation: dash 1.2s linear infinite; }
@keyframes dash { to { stroke-dashoffset: -32; } }
@media (prefers-reduced-motion: reduce) { .edge.lit, path.lit, line.lit, polyline.lit { animation: none; } }
@media (max-width: 900px) { main { grid-template-columns: 1fr; } aside { border-left: 0; border-top: 1px solid var(--line); } }
""".strip()


JS = """
const flows = __FLOWS__;
const details = __DETAILS__;
const buttons = document.querySelectorAll('[data-flow]');
const detailTitle = document.querySelector('.detail-title');
const detailBody = document.querySelector('.detail-body');

function setTheme(mode) {
  document.documentElement.classList.toggle('dark', mode === 'dark');
  localStorage.setItem('theme', mode);
}

function findTarget(key) {
  const byId = document.getElementById(key);
  if (byId) return [byId];
  return Array.from(document.querySelectorAll(`[data-k="${CSS.escape(key)}"]`));
}

function clearLit() {
  document.querySelectorAll('.lit').forEach((el) => el.classList.remove('lit'));
}

function showDetail(key) {
  const detail = details[key] || { title: key || 'Diagram', body: 'Select a node or flow to inspect details.' };
  detailTitle.textContent = detail.title || key || 'Diagram';
  detailBody.textContent = detail.body || '';
}

function activate(flowId) {
  const flow = flows.find((item) => item.id === flowId) || flows[0];
  clearLit();
  buttons.forEach((button) => button.classList.toggle('active', button.dataset.flow === flow.id));
  (flow.targets || []).forEach((target) => findTarget(target).forEach((el) => el.classList.add('lit')));
  showDetail(flow.detail || (flow.targets || [])[0]);
}

document.querySelector('[data-theme-toggle]')?.addEventListener('click', () => {
  const next = document.documentElement.classList.contains('dark') ? 'light' : 'dark';
  setTheme(next);
});

buttons.forEach((button) => button.addEventListener('click', () => activate(button.dataset.flow)));
document.querySelectorAll('[id], [data-k]').forEach((el) => {
  el.addEventListener('click', () => showDetail(el.id || el.dataset.k));
  el.style.cursor = 'pointer';
});

if (flows.length) activate(flows[0].id);
""".strip()


def load_config(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text())
    if not isinstance(data, dict):
        raise SystemExit("config must be a JSON object")
    return data


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def normalized_flows(config: dict[str, Any]) -> list[dict[str, Any]]:
    flows: list[dict[str, Any]] = []
    for index, item in enumerate(as_list(config.get("flows"))):
        if not isinstance(item, dict):
            continue
        targets = [str(target) for target in as_list(item.get("targets")) if str(target).strip()]
        flow_id = str(item.get("id") or f"flow-{index + 1}")
        flows.append(
            {
                "id": flow_id,
                "label": str(item.get("label") or flow_id),
                "targets": targets,
                "detail": str(item.get("detail") or (targets[0] if targets else "")),
            }
        )
    return flows


def normalized_details(config: dict[str, Any]) -> dict[str, dict[str, str]]:
    raw = config.get("details")
    if not isinstance(raw, dict):
        return {}
    details: dict[str, dict[str, str]] = {}
    for key, value in raw.items():
        if isinstance(value, dict):
            details[str(key)] = {
                "title": str(value.get("title") or key),
                "body": str(value.get("body") or ""),
            }
        else:
            details[str(key)] = {"title": str(key), "body": str(value)}
    return details


def render(svg: str, config: dict[str, Any]) -> str:
    title = str(config.get("title") or "Architecture diagram")
    subtitle = str(config.get("subtitle") or "")
    flows = normalized_flows(config)
    details = normalized_details(config)
    buttons = "\n".join(
        f'<button type="button" data-flow="{html.escape(flow["id"])}">{html.escape(flow["label"])}</button>'
        for flow in flows
    )
    details_json = json.dumps(details, ensure_ascii=False)
    flows_json = json.dumps(flows, ensure_ascii=False)
    boot = """
<script>
(() => {
  const saved = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (saved === 'dark' || (!saved && prefersDark)) document.documentElement.classList.add('dark');
})();
</script>
""".strip()
    script = JS.replace("__FLOWS__", flows_json).replace("__DETAILS__", details_json)
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
{boot}
<style>{CSS}</style>
</head>
<body>
<div class="shell">
  <header>
    <div>
      <h1>{html.escape(title)}</h1>
      <p class="subtitle">{html.escape(subtitle)}</p>
    </div>
    <div class="actions">
      {buttons}
      <button type="button" data-theme-toggle>Theme</button>
    </div>
  </header>
  <main>
    <section class="stage" aria-label="Diagram stage">
      {svg}
    </section>
    <aside aria-live="polite">
      <h2 class="detail-title">Diagram</h2>
      <div class="detail-body">Select a flow or node for details.</div>
    </aside>
  </main>
</div>
<script>{script}</script>
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Wrap a rendered SVG in the html-diagram standalone shell.")
    parser.add_argument("--svg", required=True, type=Path, help="Rendered SVG file to inline")
    parser.add_argument("--config", required=True, type=Path, help="JSON config with title, flows, and details")
    parser.add_argument("--out", required=True, type=Path, help="Output standalone HTML path")
    args = parser.parse_args()

    svg = args.svg.read_text()
    if "<svg" not in svg.lower():
        raise SystemExit(f"{args.svg} does not look like an SVG file")
    config = load_config(args.config)
    args.out.write_text(render(svg, config))
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
