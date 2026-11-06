// Cloned from Herdr's workspace-chrome footer (Settings, Add machine) for herdr-tui's sidebar-footer; the brand
// row stays on the shipped workspace-chrome. Wide, it is the shipped footer. On the rail each control is an
// icon centered in a 28px target, named by its tooltip, and Add machine has its own server icon.

import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
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
    if (narrow()) {
      // 1px rule + 6px + two 28px rows + 6px: the shipped footer's 69px.
      const button = (id, icon, label, action) => h_flex().id(id).relative().size(28).flex_none().items_center().justify_center().rounded(6)
        .text_color(t.dim).hover(s => s.bg(t.raised).text_color(t.foreground)).cursor_pointer()
        .role("button").accessibility_label(label).tooltip(label).on_click(action).child(svg(icon).size(16));
      return v_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).py(6).items_center()
        // An update waiting: the wide row's dot, on the gear's corner.
        .child(button("settings", "mods/workspace-chrome/settings.svg", "Settings", () => run("app.settings"))
          .when(ready, el => el.child(div().absolute().top(4).right(4).size(6).rounded_full().bg(t.accent))))
        .child(button("machine", "mods/herdr-tui-chrome/server-plus.svg", "Add machine", () => run("mod.open", { name: "machine-add" })));
    }
    const row = (id, icon, label, dim, action) => h_flex().id(id).h(28).px(8).gap(9).items_center().rounded(8)
      .text_color(dim ? t.dim : t.muted).hover(s => s.bg(t.hover).text_color(t.foreground)).cursor_pointer()
      .on_click(action).child(svg(`mods/workspace-chrome/${icon}.svg`).size(14)).child(label);
    return v_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).px(8).pt(4).pb(8).text_size(13)
      .child(row("settings", "settings", "Settings", false, () => run("app.settings"))
        .when(ready, el => el.child(div().size(6).rounded_full().bg(t.accent))))
      .child(row("machine", "plus", "Add machine", true, () => run("mod.open", { name: "machine-add" })));
  }
}
