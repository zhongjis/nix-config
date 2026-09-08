---
title: Quickshell vs Waybar — is it worth migrating?
status: idea
summary: Quickshell is a QML toolkit to *build* a shell (not a drop-in bar); migrating from Waybar is a rewrite, not a config port. Worth it only if you want deep customization and will invest in QML.
---

# Quickshell vs Waybar (Hyprland / NixOS + Home-Manager)

> Status: idea — non-binding exploration. Evidence-backed against primary/first-party sources only.

## 0. This repo's current Waybar surface (migration cost baseline)

Current config: `modules/home-manager-linux/services/waybar/`. ~13 modules
(`hyprland/workspaces`, `hyprland/window`, `tray`, `disk`, `cpu`, `temperature`,
`backlight`, `network`, `custom/memory`, `pulseaudio` + `pulseaudio#microphone`,
`custom/hyprsunset`, `battery`, `clock`) driven by JSONC with heavy Pango-markup
gruvbox theming, plus 9 helper scripts (`brightness.sh`, `volume.sh`, `weather.py`,
`key_hints.sh`, `wlogout.sh`, `cava_viz.sh`, `change_blur.sh`, `hyprsunset.sh`,
`memory_usage.sh`). Every one of these widgets' *visuals* would be re-authored in QML;
the shell scripts can largely be reused via `Process`.

## 1. What Quickshell is

- Quickshell is "a toolkit for building status bars, widgets, lockscreens, and other
  desktop components using QtQuick," used alongside a Wayland compositor/WM [1].
- It is **configured in QML** (Qt Modeling Language) [1][2]. Windows are declared as
  `PanelWindow` (bars/overlays) or `FloatingWindow` [2].
- Per-monitor bars are built explicitly with a `Variants` object driven by
  `Quickshell.screens`, creating/destroying windows as monitors connect/disconnect [2].
- It ships an IPC/process layer (`Process`, `StdioCollector`) and Unix-socket IPC/socket
  servers [2][6]. Live-reloads config on save [2].
- **Maturity/stability:** "Quickshell is still in a somewhat early stage of development.
  There will be breaking changes before 1.0, however a migration guide will be provided" [3].
  Versioning is pre-1.0 (docs published for v0.1.0 / v0.2.0 / v0.3.0; nixpkgs ships 0.2.1) [3][5][7].
  **The API is explicitly NOT declared stable** [3]. Licensed LGPL-3.0 [8].
- Source is hosted on Forgejo (git.outfoxxed.me) with a GitHub mirror
  (github.com/quickshell-mirror/quickshell) [8].

## 2. What Quickshell provides vs Waybar

**Waybar** is a config-driven (JSON/JSONC) GTK bar with a large set of **prebuilt modules**:
workspaces (Sway/Hyprland/River/Niri/…), Battery/UPower, Network, Bluetooth, PulseAudio/
WirePlumber, MPRIS/MPD, Clock, **System tray**, backlight, CPU/memory/temp, custom scripts —
all documented per-module and enabled via config [4].

**Quickshell** is a **toolkit/framework**, not a drop-in bar. There are no prebuilt
"modules" you enable in config; you assemble the bar yourself in QML from primitives
and support libraries [1][2]. The guided intro builds a clock bar by hand (PanelWindow +
Text + Process(`date`) + Timer, then refactored into components/singletons) [2].

**What Quickshell gives out of the box** (support libraries / service types you wire up
yourself in QML) [6][7]:
- `Quickshell.Services.SystemTray` — system tray (StatusNotifier) [6][7]
- `Quickshell.Services.Pipewire` — audio nodes [6][7]
- `Quickshell.Services.UPower` — battery/power [7]
- `Quickshell.Networking` — network [7]
- `Quickshell.Bluetooth` — bluetooth [7]
- `Quickshell.Services.Mpris` — media players [6][7]
- `Quickshell.Services.Notifications` — implement a notification daemon [7]
- `Quickshell.Hyprland`, `Quickshell.I3` — compositor integration [7]
- `Quickshell.Services.Pam` / `Polkit` / `Greetd`, session lock — auth/lockscreen [6][7]
- `SystemClock`, `Quickshell.Widgets` (bundled widgets), `Quickshell.Io` [2][7]

**You must build yourself:** the bar layout, the workspace widget, and the visual/UX of
every "module" (tray icons rendering, battery display, network indicator, audio slider,
notification popups). Quickshell provides the *data/services*; you provide the *UI* [2][6][7].

## 3. Feature / effort delta

- **No ready-made modules:** every Waybar module (workspaces, clock, battery, network,
  audio, tray) has a Quickshell *service/type* but **not a prebuilt widget** — the widget
  is hand-written QML [2][6][7].
- **System tray:** supported via `SERVICE_STATUS_NOTIFIER` (StatusNotifier D-Bus protocol,
  `Quickshell.Services.SystemTray` + `Quickshell.DBusMenu`) [6][7]. (Waybar tray uses the
  same StatusNotifier/appindicator ecosystem [4].)
- **Wayland protocols:** wlroots layer-shell (`zwlr-layer-shell-v1`) for bars/overlays/
  backgrounds; `ext-session-lock-v1` (lockscreen); foreign-toplevel-management; screencopy
  (ext-image-copy-capture / wlr-screencopy / hyprland-toplevel-export); X11 panels too [6].
- **Hyprland IPC:** first-class `Quickshell.Hyprland` integration (event/request sockets,
  `dispatch()`, `monitorFor()`), plus Hyprland global-shortcuts and focus-grab protocols [6][9].
- Also has i3/Sway IPC [6].

## 4. NixOS / Home-Manager integration

- **In nixpkgs:** yes — package `quickshell` (nixpkgs shows 0.2.1, LGPL-3.0) [5][7].
- **Official flake:** the repo has an embedded flake usable from either mirror
  (`git+https://git.outfoxxed.me/outfoxxed/quickshell` or `github:quickshell-mirror/quickshell`);
  package exposed as `quickshell.packages.<system>.default`; **strongly recommends
  `inputs.nixpkgs.follows = "nixpkgs"`** because mismatched system deps cause crashes
  (Quickshell links private Qt APIs and must be rebuilt per Qt release) [3][6]. Repo root
  also contains `flake.nix`, `overlay.nix`, `default.nix` [8].
- **Home-Manager module:** yes, on HM **master** — `programs.quickshell` (maintainer
  `justdeeevin`): `enable`, `package`, `configs` (attrset of config paths → written to
  `xdg.configFile "quickshell/<name>"`), `activeConfig`, and an optional
  `systemd` user service targeting the WM session target [10]. (Not yet in released HM
  channels at time of writing — the HM option index returned no match [11]; consume via
  HM master/flake.)
- **Nix/qmlls caveat:** for LSP to find QML modules, docs advise setting `qt.enable = true`
  and installing quickshell globally so `QML2_IMPORT_PATH` is populated [3].

## 5. Effort & risk of migration

- **It is a rewrite, not a config port.** Waybar config is declarative JSONC selecting
  modules [4]; Quickshell requires authoring QML components, wiring services, and building
  every widget's layout/logic/styling from scratch [2]. No automated migration path exists.
- **Learning curve:** you must learn QML/QtQuick (property bindings, components,
  singletons, signal handlers) — the intro itself walks through these concepts [2]. qmlls
  LSP support exists but has known gaps (singletons, `PanelWindow`, `root:` imports don't
  resolve) [3].
- **Stability risk:** pre-1.0, breaking changes expected before 1.0 (migration guide
  promised) [3]. On non-Nix rolling distros it "may break whenever Qt is updated" [3]; on
  Nix the flake+`follows` mitigates this by rebuilding against your Qt [3][6].

## 6. When Quickshell wins vs stay on Waybar

**Stay on Waybar if:** you want a working bar fast, are happy with prebuilt modules and
JSONC/CSS theming, and value stability over deep customization [4].

**Choose Quickshell if:** you want a fully custom desktop shell (bars + widgets +
lockscreen + notifications + launchers) with pixel-level control, reactive QML UI, deep
Hyprland IPC, and are willing to learn QML and accept pre-1.0 churn [1][2][3][6].

---

## Sources
[1] Quickshell — home (https://quickshell.org/)
[2] Quickshell docs — Introduction / guided bar tutorial (https://quickshell.org/docs/guide/introduction/)
[3] Quickshell docs — Installation & Setup (https://quickshell.org/docs/guide/install-setup)
[4] Waybar — README, Alexays/Waybar (https://github.com/Alexays/Waybar)
[5] nixpkgs — package `quickshell` info via NixOS search (https://search.nixos.org/packages?query=quickshell)
[6] Quickshell — BUILD.md (feature/protocol list), git.outfoxxed.me mirror (https://git.outfoxxed.me/quickshell/quickshell/raw/branch/master/BUILD.md)
[7] Quickshell docs — Module/Type listing v0.3.0 (https://quickshell.org/docs/v0.3.0/types/)
[8] Quickshell — repo README, github.com/quickshell-mirror/quickshell (https://github.com/quickshell-mirror/quickshell)
[9] Quickshell docs — Quickshell.Hyprland type (https://quickshell.org/docs/v0.1.0/types/Quickshell.Hyprland/Hyprland/)
[10] Home-Manager — modules/programs/quickshell.nix, nix-community/home-manager @ master (https://github.com/nix-community/home-manager/blob/master/modules/programs/quickshell.nix)
[11] NixOS/HM option index query for `programs.quickshell.enable` — not found in released HM index (https://home-manager-options.extranix.com/)
