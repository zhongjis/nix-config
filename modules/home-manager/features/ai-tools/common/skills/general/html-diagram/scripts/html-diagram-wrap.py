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
  },
  "fitViewBox": true,
  "keyboardGraph": true
}

Targets match SVG element id values first, then data-k values. By default the
script fits the SVG viewBox to interactive content; set fitViewBox=false to
preserve intentional outer margins or decorative zones.
Set keyboardGraph=false to avoid per-node tab stops in very dense diagrams.
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
  --panel: rgba(255, 255, 255, 0.94);
  --text: #0f172a;
  --muted: #64748b;
  --line: rgba(15, 23, 42, 0.14);
  --accent: #2563eb;
  --accent-soft: rgba(37, 99, 235, 0.14);
  --active: #f97316;
  --active-soft: rgba(249, 115, 22, 0.20);
  --dim-opacity: 0.18;
  --shadow: 0 22px 70px rgba(15, 23, 42, 0.16);
}
html.dark {
  color-scheme: dark;
  --bg: #080b14;
  --panel: rgba(15, 23, 42, 0.88);
  --text: #e5e7eb;
  --muted: #94a3b8;
  --line: rgba(226, 232, 240, 0.16);
  --accent: #60a5fa;
  --accent-soft: rgba(96, 165, 250, 0.16);
  --active: #fb923c;
  --active-soft: rgba(251, 146, 60, 0.22);
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
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--line);
  backdrop-filter: blur(16px);
}
h1 { margin: 0; font-size: clamp(1.15rem, 1.8vw, 1.7rem); letter-spacing: -0.03em; }
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
button:hover { border-color: var(--accent); background: var(--accent-soft); }
button.active { border-color: var(--active); background: var(--active-soft); box-shadow: 0 0 0 2px var(--active-soft); }
button:focus-visible, [tabindex="0"]:focus-visible { outline: 2px solid var(--active); outline-offset: 3px; }
main { display: grid; grid-template-columns: minmax(0, 1fr); grid-template-rows: minmax(0, 1fr); min-height: 0; }
.shell.has-details main { grid-template-rows: minmax(0, 1fr) auto; }
.stage { min-width: 0; min-height: 0; overflow: auto; padding: 0.75rem; }
.stage svg { display: block; width: 100%; height: auto; min-width: min(100%, 720px); }
aside {
  border-top: 1px solid var(--line);
  padding: 0.75rem 1rem;
  background: var(--panel);
  box-shadow: var(--shadow);
  max-height: 8rem;
  overflow: auto;
}
aside[hidden] { display: none; }
.detail-title { margin: 0 0 0.5rem; font-size: 1rem; }
.detail-body { color: var(--muted); white-space: pre-wrap; }
.lit, .lit * { stroke: var(--active) !important; }
.lit:not(text), .lit *:not(text) { filter: drop-shadow(0 0 12px var(--active-soft)); }
.node.lit rect, .d2-node.lit rect, [data-k].lit rect, rect.lit { fill: var(--active-soft) !important; stroke: var(--active) !important; stroke-width: 4px !important; }
.stage.flowing .d2-node, .stage.flowing .d2-edge, .stage.flowing .node, .stage.flowing .edge, .stage.flowing [data-k] { opacity: var(--dim-opacity); transition: opacity 0.16s ease, filter 0.16s ease; }
.stage.flowing .lit, .stage.flowing .lit * { opacity: 1 !important; }
.edge.lit, .d2-edge.lit .connection, path.lit, line.lit, polyline.lit { stroke: var(--active) !important; stroke-width: 4px !important; stroke-dasharray: 10 6; animation: dash 1.2s linear infinite; }
@keyframes dash { to { stroke-dashoffset: -32; } }
@media (prefers-reduced-motion: reduce) { .edge.lit, .d2-edge.lit .connection, path.lit, line.lit, polyline.lit { animation: none; } }
@media (max-width: 900px) { .stage svg { min-width: 720px; } }
""".strip()


JS = """
const flows = __FLOWS__;
const details = __DETAILS__;
const fitViewBox = __FIT_VIEWBOX__;
const keyboardGraph = __KEYBOARD_GRAPH__;
const buttons = document.querySelectorAll('[data-flow]');
const stage = document.querySelector('.stage');
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

function markerId(value) {
  return value?.match(/^url\(#(.+)\)$/)?.[1] || '';
}

function activeMarkerFor(id) {
  const activeId = `${id}-active`;
  let marker = document.getElementById(activeId);
  if (marker) return activeId;
  const source = document.getElementById(id);
  if (!source) return id;
  marker = source.cloneNode(true);
  marker.id = activeId;
  marker.querySelectorAll('path, polygon, polyline, line').forEach((el) => {
    if (el.getAttribute('fill') !== 'none') el.style.fill = 'var(--active)';
    if (el.getAttribute('stroke') !== 'none') el.style.stroke = 'var(--active)';
  });
  source.parentNode?.appendChild(marker);
  return activeId;
}

function resetActiveMarkers() {
  document.querySelectorAll('[data-marker-end], [data-marker-start], [data-marker-mid]').forEach((el) => {
    ['markerEnd', 'markerStart', 'markerMid'].forEach((key) => {
      const attr = key.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);
      if (!el.dataset[key]) return;
      el.setAttribute(attr, el.dataset[key]);
      delete el.dataset[key];
    });
  });
}

function clearLit() {
  resetActiveMarkers();
  document.querySelectorAll('.lit').forEach((el) => el.classList.remove('lit'));
}

function showDetail(key) {
  const detail = details[key] || { title: key || 'Diagram', body: 'Select a node or flow to inspect details.' };
  detailTitle.textContent = detail.title || key || 'Diagram';
  detailBody.textContent = detail.body || '';
}

function lightTargets(targets) {
  clearLit();
  stage?.classList.toggle('flowing', targets.length > 0);
  targets.forEach((target) => findTarget(target).forEach((el) => el.classList.add('lit')));
  document.querySelectorAll('.lit [marker-end], .lit [marker-start], .lit [marker-mid], .lit[marker-end], .lit[marker-start], .lit[marker-mid]').forEach((el) => {
    ['marker-end', 'marker-start', 'marker-mid'].forEach((attr) => {
      const value = el.getAttribute(attr);
      const id = markerId(value);
      if (!id) return;
      const datasetKey = attr.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
      el.dataset[datasetKey] = value;
      el.setAttribute(attr, `url(#${activeMarkerFor(id)})`);
    });
  });
}

function setActiveButton(flowId) {
  buttons.forEach((button) => {
    const active = button.dataset.flow === flowId;
    button.classList.toggle('active', active);
    button.setAttribute('aria-pressed', String(active));
  });
}

function selectKey(key) {
  setActiveButton('');
  lightTargets(key ? [key] : []);
  showDetail(key);
}

function clearSelection() {
  setActiveButton('');
  lightTargets([]);
  showDetail('');
}

function fitSvgToContent() {
  const svg = stage?.querySelector('svg');
  if (!svg || !svg.viewBox) return;
  try {
    const candidates = Array.from(svg.querySelectorAll('[data-k], .node, .d2-node, .d2-zone, .edge, .d2-edge'))
      .filter((el) => el !== svg);
    const boxes = candidates.length ? candidates.map((el) => el.getBBox()) : [svg.getBBox()];
    const usable = boxes.filter((box) => box && box.width >= 0 && box.height >= 0);
    if (!usable.length) return;
    const minX = Math.min(...usable.map((box) => box.x));
    const minY = Math.min(...usable.map((box) => box.y));
    const maxX = Math.max(...usable.map((box) => box.x + box.width));
    const maxY = Math.max(...usable.map((box) => box.y + box.height));
    if (maxX <= minX || maxY <= minY) return;
    const pad = 32;
    const next = [minX - pad, minY - pad, maxX - minX + pad * 2, maxY - minY + pad * 2];
    const current = svg.viewBox.baseVal;
    const currentArea = current.width * current.height;
    const nextArea = next[2] * next[3];
    if (currentArea > 0 && nextArea / currentArea < 0.92) {
      svg.setAttribute('viewBox', next.map((value) => Number(value.toFixed(2))).join(' '));
      svg.dataset.fitViewbox = candidates.length ? 'interactive-content' : 'content';
    }
  } catch {
    // Some exported SVGs cannot compute getBBox before paint; leave them unchanged.
  }
}

function activate(flowId) {
  const flow = flows.find((item) => item.id === flowId) || flows[0];
  const targets = flow?.targets || [];
  setActiveButton(flow.id);
  lightTargets(targets);
  showDetail(flow.detail || targets[0]);
}

document.querySelector('[data-theme-toggle]')?.addEventListener('click', () => {
  const next = document.documentElement.classList.contains('dark') ? 'light' : 'dark';
  setTheme(next);
});

function closestGraphElement(start) {
  let el = start instanceof Element ? start : start?.parentElement;
  const ignoredTags = new Set(['svg', 'defs', 'marker', 'clippath', 'mask', 'pattern', 'style', 'script']);
  let fallback = null;
  while (el && el !== stage) {
    const graphKey = el.dataset?.k || el.id;
    const isGraphShape = el.classList?.contains('node') || el.classList?.contains('d2-node') || el.classList?.contains('edge') || el.classList?.contains('d2-edge') || el.classList?.contains('d2-zone');
    if (isGraphShape && graphKey) return el;
    if (!fallback && graphKey && !ignoredTags.has(el.tagName.toLowerCase())) fallback = el;
    el = el.parentElement;
  }
  return fallback;
}

buttons.forEach((button) => button.addEventListener('click', () => activate(button.dataset.flow)));
stage?.addEventListener('click', (event) => {
  const target = closestGraphElement(event.target);
  if (!target) {
    clearSelection();
    return;
  }
  selectKey(target.dataset?.k || target.id);
});
document.querySelectorAll('[data-k], .node, .d2-node, .edge, .d2-edge, .d2-zone').forEach((el) => {
  const key = el.dataset?.k || el.id;
  if (!key) return;
  el.style.cursor = 'pointer';
  if (!keyboardGraph) return;
  el.setAttribute('tabindex', '0');
  el.setAttribute('role', 'button');
  if (key && !el.getAttribute('aria-label')) el.setAttribute('aria-label', key);
  el.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    event.preventDefault();
    selectKey(key);
  });
});
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') clearSelection();
});

setActiveButton('');
if (fitViewBox) fitSvgToContent();
if (flows.length && (!flows[0].targets?.length || flows[0].id === 'all')) activate(flows[0].id);
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
    fit_viewbox_json = json.dumps(config.get("fitViewBox") is not False)
    keyboard_graph_json = json.dumps(config.get("keyboardGraph") is not False)
    script = (
        JS.replace("__FLOWS__", flows_json)
        .replace("__DETAILS__", details_json)
        .replace("__FIT_VIEWBOX__", fit_viewbox_json)
        .replace("__KEYBOARD_GRAPH__", keyboard_graph_json)
    )
    shell_class = "shell has-details" if details else "shell"
    aside_hidden = "" if details else " hidden"
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
<div class="{shell_class}">
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
    <aside aria-live="polite"{aside_hidden}>
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
