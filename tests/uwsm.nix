let
  f = builtins.getFlake (toString ../.);
  c = f.nixosConfigurations.framework-16.config;
  pkgs = f.nixosConfigurations.framework-16.pkgs;
  lib = pkgs.lib;
  hm = f.homeConfigurations."zshen@framework-16".config;
  execOnce = hm.wayland.windowManager.hyprland.settings.exec-once;
  xdg = lib.findFirst (lib.hasSuffix "/bin/xdg") (throw "missing xdg startup") execOnce;
  original = f.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.override {
    enableXWayland = c.programs.hyprland.xwayland.enable;
  };
  installed = pkgs.buildEnv {
    name = "uwsm-installed";
    paths = [c.programs.hyprland.package];
  };
in
  pkgs.runCommand "uwsm-regression" {} ''
    fail() { echo "FAIL: $*" >&2; exit 1; }
    test -x ${installed}/bin/Hyprland || fail 'installed binary'
    test "$(readlink -f ${installed}/bin/Hyprland)" = "$(readlink -f ${original}/bin/Hyprland)" || fail 'installed binary identity'
    test -d ${installed}/share/man || fail 'installed man pages'
    diff -r ${original.man}/share/man ${installed}/share/man || fail 'installed man pages preserved'
    test '${lib.getMan c.programs.hyprland.package}' = '${original.man}' || fail 'getMan output identity'
    test '${lib.getDev c.programs.hyprland.package}' = '${original.dev}' || fail 'getDev output identity'
    echo 'PASS: package output integration'
    desktop=${c.services.displayManager.sessionData.desktops}/share/wayland-sessions
    grep -Fx 'Exec=${lib.getExe' c.programs.uwsm.package "uwsm"} start -e -D Hyprland hyprland.desktop' "$desktop/hyprland-uwsm.desktop" || fail 'absolute UWSM Exec'
    grep -Fx 'TryExec=${lib.getExe' c.programs.uwsm.package "uwsm"}' "$desktop/hyprland-uwsm.desktop" || fail 'absolute UWSM TryExec'
    grep -Fx 'DesktopNames=Hyprland' "$desktop/hyprland-uwsm.desktop" || fail DesktopNames
    test '${builtins.toJSON c.programs.uwsm.enable}' = true || fail 'UWSM enabled'
    test '${c.services.displayManager.defaultSession}' = hyprland || fail 'direct default preserved'
    cmp "$desktop/hyprland.desktop" ${original}/share/wayland-sessions/hyprland.desktop || fail 'direct desktop preserved'
    test "$(readlink -f ${c.programs.hyprland.package}/bin/Hyprland)" = "$(readlink -f ${original}/bin/Hyprland)" || fail 'binary identity'
    test '${builtins.toJSON c.programs.hyprland.package.providedSessions}' = '${builtins.toJSON original.providedSessions}' || fail providedSessions
    echo 'PASS: desktop lifecycle'
    mkdir stubs
    export LOG="$PWD/commands" PATH="$PWD/stubs:$PATH"
    cat > stubs/uwsm <<'SH'
    #!${pkgs.runtimeShell}
    echo "uwsm $*" >> "$LOG"
    if [ "$*" = 'check is-active hyprland.desktop' ]; then
      case "$STATE" in active|activating) exit 0;; *) exit 1;; esac
    fi
    SH
    for command in systemctl dbus-update-activation-environment hyprctl killall hyprlock i3lock; do
      cat > "stubs/$command" <<'SH'
    #!${pkgs.runtimeShell}
    echo "$(basename "$0") $*" >> "$LOG"
    SH
    done
    chmod +x stubs/*
    for STATE in active activating unmanaged; do
      export STATE
      : > "$LOG"
      ${xdg}
      echo 'uwsm check is-active hyprland.desktop' > expected
      if [ "$STATE" = unmanaged ]; then
        printf '%s\n' 'systemctl --user import-environment PATH' 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP' 'systemctl --user restart xdg-desktop-portal.service' >> expected
      fi
      diff -u expected "$LOG" || fail "startup $STATE"
    done
    test '${builtins.toJSON (builtins.any (lib.hasInfix "dbus-update-activation-environment") execOnce)}' = false || fail 'unguarded exec-once D-Bus import'
    test '${builtins.toJSON hm.wayland.windowManager.hyprland.systemd.enable}' = false || fail 'HM systemd integration'
    echo 'PASS: startup lifecycle'
    cat > stubs/rofi <<'SH'
    #!${pkgs.runtimeShell}
    cat >/dev/null
    printf '%s\n' "$CHOICE"
    SH
    chmod +x stubs/rofi
    export XDG_SESSION_TYPE=wayland CHOICE='Log Out'
    for DESKTOP_SESSION in hyprland hyprland-uwsm unknown i3 sway; do
      export DESKTOP_SESSION
      for STATE in active activating unmanaged; do
        export STATE
        : > "$LOG"
        ${pkgs.runtimeShell} ${../modules/home-manager-linux/features/rofi/rofi-toggle-power-menu.sh}
        case "$DESKTOP_SESSION" in
          i3|sway) echo "killall $DESKTOP_SESSION" > expected ;;
          *)
            echo 'uwsm check is-active hyprland.desktop' > expected
            if [ "$STATE" = unmanaged ]; then
              echo 'hyprctl dispatch exit' >> expected
            else
              echo 'uwsm stop' >> expected
            fi ;;
        esac
        diff -u expected "$LOG" || fail "logout $DESKTOP_SESSION $STATE"
      done
    done
    for CHOICE in Cancel Restart 'Power OFF' Suspend; do
      export CHOICE
      : > "$LOG"
      status=0
      ${pkgs.runtimeShell} ${../modules/home-manager-linux/features/rofi/rofi-toggle-power-menu.sh} || status=$?
      case "$CHOICE" in
        Cancel) test "$status" = 1 || fail 'cancel status'; : > expected ;;
        Restart) echo 'systemctl reboot' > expected ;;
        'Power OFF') echo 'systemctl poweroff' > expected ;;
        Suspend) printf '%s\n' 'systemctl suspend' 'hyprlock ' > expected ;;
      esac
      diff -u expected "$LOG" || fail "menu $CHOICE"
    done
    echo 'PASS: logout lifecycle and menu baseline'
    touch "$out"
  ''
