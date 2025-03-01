{config, ...}: {
  services.dunst = {
    enable = true;
  };

  xdg.configFile."dunst/dunstrc".text = with config.lib.stylix.colors; ''
    #      _                 _
    #   __| |_   _ _ __  ___| |_
    #  / _` | | | | '_ \/ __| __|
    # | (_| | |_| | | | \__ \ |_
    #  \__,_|\__,_|_| |_|___/\__|
    #
    #
    # by Stephan Raabe (2023)
    # -----------------------------------------------------

    # See dunst(5) for all configuration options

    [global]
        ### Display ###
        monitor = 0
        follow = mouse

        ### Geometry ###
        width = 300
        height = (0,300)
        origin = top-right
        offset = 30x30
        scale = 0
        notification_limit = 20

        ### Progress bar ###
        progress_bar = true
        progress_bar_height = 10
        progress_bar_frame_width = 1
        progress_bar_min_width = 150
        progress_bar_max_width = 300
        progress_bar_corner_radius = 10
        icon_corner_radius = 0
        indicate_hidden = yes
        transparency = 30
        separator_height = 2
        padding = 8
        horizontal_padding = 8
        text_icon_padding = 0
        frame_width = 1
        frame_color = "#ffffff"
        gap_size = 0
        # separator_color = frame # managed by stylix

        # Sort messages by urgency.
        sort = yes

        # Don't remove messages, if the user is idle (no mouse or keyboard input)
        # for longer than idle_threshold seconds.
        # Set to 0 to disable.
        # A client can set the 'transient' hint to bypass this. See the rules
        # section for how to disable this if necessary
        # idle_threshold = 120

        ### Text ###
        # font = "FiraCode Nerd Font 10" # managed by stylix
        line_height = 1
        markup = full
        format = "<b>%s</b>\n%b"
        alignment = left
        vertical_alignment = center
        show_age_threshold = 60
        ellipsize = middle
        ignore_newline = no
        stack_duplicates = true
        hide_duplicate_count = false
        show_indicators = yes

        ### Icons ###
        enable_recursive_icon_lookup = true
        icon_theme = "Papirus-Dark,Adwaita"
        icon_position = left
        min_icon_size = 32
        max_icon_size = 128
        # icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/ # managed by stylix

        ### History ###
        sticky_history = yes
        history_length = 20

        ### Misc/Advanced ###
        dmenu = /usr/bin/dmenu -p dunst:
        browser = /usr/bin/xdg-open

        always_run_script = true
        title = Dunst
        class = Dunst

        corner_radius = 10
        ignore_dbusclose = false

        ### Wayland ###
        force_xwayland = false

        ### mouse

        # Defines list of actions for each mouse event
        # Possible values are:
        # * none: Don't do anything.
        # * do_action: Invoke the action determined by the action_name rule. If there is no
        #              such action, open the context menu.
        # * open_url: If the notification has exactly one url, open it. If there are multiple
        #             ones, open the context menu.
        # * close_current: Close current notification.
        # * close_all: Close all notifications.
        # * context: Open context menu for the notification.
        # * context_all: Open context menu for all notifications.
        # These values can be strung together for each mouse event, and
        # will be executed in sequence.
        mouse_left_click = close_current
        mouse_middle_click = do_action, close_current
        mouse_right_click = close_all

    [experimental]
        per_monitor_dpi = true

    [urgency_low]
        # note: managed by stylix
        # background = "${base01}"
        # foreground = "${base05}"
        # frame_color = "${base0B}"
        timeout = 6

    [urgency_normal]
        # note: managed by stylix
        # background = "${base01}"
        # foreground = "${base05}"
        # frame_color = "${base0E}"
        timeout = 6
        # Icon for notifications with normal urgency, uncomment to enable
        #default_icon = /path/to/icon

    [urgency_critical]
        # note: managed by stylix
        # background = "${base01}"
        # foreground = "${base05}"
        # frame_color = "${base08}"
        timeout = 6
        # Icon for notifications with critical urgency, uncomment to enable
        #default_icon = /path/to/icon
  '';
}
