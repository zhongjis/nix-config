{
  pkgs,
  lib,
  currentSystemName,
  ...
}: let
  fontSize = if currentSystemName == "mac-m1-max" then 18 else 13;
in {
  programs.zed-editor = {
    enable = true;

    # Install Zed remote server for remote connections
    installRemoteServer = true;

    # Allow user to modify settings through Zed UI
    mutableUserSettings = true;
    mutableUserKeymaps = true;
    mutableUserTasks = true;
    mutableUserDebug = false;

    # Zed extensions for enhanced functionality
    extensions = [
      # OpenCode agent extension (as requested)
      "opencode-agent"

      # Basic language support and syntax highlighting
      "nix"
      "rust"
      "python"
      "typescript"
      "javascript"
      "go"
      "json"
      "yaml"
      "toml"
      "markdown"
      "sql"
      "dockerfile"
      "bash"
      # Elvish support
      "elvish"
    ];

    # User settings configuration for ~/.config/zed/settings.json
    userSettings = {
      # Theme configuration - follow system preference
      theme = {
        mode = "system";
        dark = "One Dark";
        light = "One Light";
      };

      # Icon theme
      icon_theme = {
        mode = "system";
        dark = "Zed (Default)";
        light = "Zed (Default)";
      };

      # Enable vim mode (as requested)
      vim_mode = true;

      # Vim operator replacement for easier text manipulation
      vim_operator_replace_mode = true;

      # Use System UI font for interface
      ui_font_family = ".SystemUIFont";
      ui_font_size = 16;

      # Buffer font settings - code editing
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_size = fontSize;
      buffer_font_weight = 400;
      buffer_line_height = "standard";

      # Soft wrap configuration
      soft_wrap = "preferred_line_length";
      preferred_line_length = 100;

      # Tab settings
      tab_size = 2;
      hard_tabs = false;
      trim_on_paste = true;

      # Autosave configuration
      autosave = "on_focus_change";

      # Format on save
      format_on_save = "on_focus_change";

      # Ensure clean files on save
      ensure_final_newline_on_save = true;
      remove_trailing_whitespace_on_save = true;

      # Scroll configuration
      scroll_beyond_last_line = false;
      vertical_scroll_margin = 10;
      horizontal_scroll_margin = 10;

      # Cursor configuration
      cursor_blink = true;
      cursor_smooth_caret_animation = "linear";

      # Bracket pair configuration
      use_default_bracket_pair_colorizer = true;
      highlight_bracket_matches = true;

      # gutter configuration
      gutter = {
        show_git_diff_gutter = true;
        show_git_gutter = true;
        show_line_numbers = true;
        show_code_actions = true;
        show_spelling_placeholder = false;
      };

      # Terminal configuration
      terminal = {
        font_family = "FiraCode Nerd Font Mono";
        font_size = fontSize;
        line_height = "standard";
        blinking = "off";
        copy_on_select = true;
        shell = "${lib.getExe pkgs.zsh}";
      };

      # Projects configuration
      projects_online_by_default = true;

      # Telemetry (disable for privacy)
      telemetry = {
        enable = false;
      };

      # Language-specific configurations
      languages = {
        Nix = {
          formatter = "language_server";
          tab_size = 2;
          hard_tabs = false;
        };

        Rust = {
          formatter = "language_server";
          tab_size = 4;
          hard_tabs = false;
        };

        Python = {
          formatter = "language_server";
          tab_size = 4;
          hard_tabs = false;
        };

        TypeScript = {
          tab_size = 2;
          hard_tabs = false;
        };

        TypeScriptReact = {
          tab_size = 2;
          hard_tabs = false;
        };

        JavaScript = {
          tab_size = 2;
          hard_tabs = false;
        };

        JavaScriptReact = {
          tab_size = 2;
          hard_tabs = false;
        };

        Go = {
          tab_size = 4;
          hard_tabs = true;
        };

        JSON = {
          tab_size = 2;
          hard_tabs = false;
        };

        YAML = {
          tab_size = 2;
          hard_tabs = false;
        };

        Markdown = {
          tab_size = 2;
          hard_tabs = false;
          soft_wrap = "none";
        };

        "Shell Script" = {
          tab_size = 2;
          hard_tabs = false;
        };

        SQL = {
          tab_size = 2;
          hard_tabs = false;
        };

        Dockerfile = {
          tab_size = 2;
          hard_tabs = false;
        };

        Elvish = {
          tab_size = 2;
          hard_tabs = false;
        };
      };

      # LSP configuration for better language support
      lsp = {
        # Use nixd for Nix language server if available
        nix = {
          command = "nixd";
          args = ["--no-config"];
        };
      };

      # Enable direnv integration
      load_direnv = "shell_hook";

      # Copilot configuration (disabled by default, can be enabled via Zed UI)
      copilot = {
        enable = false;
      };
    };

    # User keymaps for vim-like bindings and custom shortcuts
    userKeymaps = {
      # Vim mode bindings are enabled by default
      # Additional custom keybindings can be added here
      "Standard" = {
        # Quick file search
        bindings = {
          "cmd-p" = "file_finder";
          "cmd-shift-p" = "command_palette";
          "cmd-shift-f" = "global_search";
          "cmd-b" = "toggle_left_panel";
          "cmd-shift-b" = "toggle_right_panel";
          "cmd-j" = "toggle_bottom_panel";
        };
      };
    };

    # Default tasks for common operations
    userTasks = {
      # Terminal task
      Terminal = {
        label = "Terminal";
        cmd = "${lib.getExe pkgs.zsh}";
        bindings = {
          "ctrl-`" = "toggle";
        };
      };

      # Build task (auto-detected based on project)
      Build = {
        label = "Build";
        cmd = "cargo build";
        bindings = {
          "cmd-b" = "toggle";
        };
      };

      # Test task
      Test = {
        label = "Test";
        cmd = "cargo test";
        bindings = {
          "cmd-shift-t" = "toggle";
        };
      };
    };
  };
}
