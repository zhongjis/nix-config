// Herdr's workspace-chrome footer (Settings, Add machine) for herdr-tui's sidebar-footer, drawn as herdr-t3's footer:
// one row of icon buttons named by their tooltips; the brand row stays on the shipped workspace-chrome.
// On the rail the buttons shrink to 28px so both fit its 76px (macOS) width.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, run, updates, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

export default class SidebarFooter extends View {
  render() {
    const t = theme();
    const ready = Boolean(updates().app.ready);
    const rail = narrow(), size = rail ? 28 : 32;
    const button = (id, icon, label, action) => h_flex().id(id).relative().size(size).flex_none().items_center().justify_center().rounded(8)
      .text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground)).cursor_pointer()
      .role("button").accessibility_label(label).tooltip(label).on_click(action).child(svg(icon).size(16));
    // 4 above the row, 8 in (centered on the rail): herdr-t3's footer in its 44px block.
    return h_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).pt(4).gap(4).items_start()
      .when(rail, el => el.justify_center()).when(!rail, el => el.px(8))
      // An update waiting: a dot on the gear's corner.
      .child(button("settings", "mods/workspace-chrome/settings.svg", "Settings", () => run("app.settings"))
        .when(ready, el => el.child(div().absolute().top(4).right(4).size(6).rounded_full().bg(t.accent))))
      .child(button("machine", "mods/herdr-tui-chrome/server.svg", "Add machine", () => run("mod.open", { name: "machine-add" })));
  }
}
