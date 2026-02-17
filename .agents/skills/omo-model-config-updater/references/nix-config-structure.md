# Nix Config Structure — OMO Model Configuration

## oh-my-opencode.nix Structure

```
modules/home-manager/features/ai-tools/opencode/plugins/oh-my-opencode.nix
```

### Key Sections

```nix
{pkgs, lib, config, hasPlugin, aiProfileHelpers, ...}: let
  jsonFormat = pkgs.formats.json {};
  cfg = config.programs.opencode.ohMyOpenCode;
in {
  # ... option definition ...

  config = lib.mkIf (hasPlugin "oh-my-opencode") {
    programs.opencode.ohMyOpenCode.settings = let
      sharedConfig = {
        "$schema" = "https://...oh-my-opencode.schema.json";
        # agents.librarian prompt_append, claude_code toggles, etc.
      };

      personalOverrides = sharedConfig // {
        agents = { /* ... agent model assignments ... */ };
        categories = { /* ... category model assignments ... */ };
      };

      workOverrides = sharedConfig // {
        agents = { /* ... DO NOT TOUCH unless asked ... */ };
        categories = { /* ... */ };
      };

      profileOverrides =
        if aiProfileHelpers.isWork
        then workOverrides
        else personalOverrides;

      baseConfig = lib.recursiveUpdate sharedConfig profileOverrides;
    in baseConfig;

    # Output file
    xdg.configFile."opencode/oh-my-opencode.jsonc".text = builtins.toJSON cfg.settings;
  };
}
```

### Agent Assignment Pattern

```nix
agents = {
  sisyphus = {
    model = "github-copilot/claude-opus-4.6";
    tier = "max";  # optional: max, xhigh, high, medium, low
  };
  oracle = {
    model = "github-copilot/gpt-5.2";
    tier = "high";
  };
  # ... repeat for all 9 agents
};
```

### Category Assignment Pattern

```nix
categories = {
  visual-engineering = {
    model = "google/gemini-3-pro-preview";
    # tier is optional
  };
  ultrabrain = {
    model = "github-copilot/gpt-5.2-codex";
    tier = "xhigh";
  };
  # ... repeat for all 8 categories
};
```

## antigravity-auth.nix Structure

```
modules/home-manager/features/ai-tools/opencode/plugins/antigravity-auth.nix
```

### Model Definition Pattern

```nix
{lib, hasPlugin, ...}:
lib.mkIf (hasPlugin "opencode-antigravity-auth") {
  programs.opencode.settings = {
    provider.google.models = {
      # Basic model (no thinking variants)
      model-name = {
        name = "model-name";
        max_tokens = 65536;
        context_length = 1048576;
        supports_streaming = true;
        modalities.input = ["text" "image" "pdf"];
        modalities.output = ["text"];
      };

      # Model with thinking variants
      model-name-thinking = {
        name = "model-name-thinking";
        max_tokens = 64000;
        context_length = 200000;
        supports_streaming = true;
        modalities.input = ["text" "image" "pdf"];
        modalities.output = ["text"];
        variants = {
          low = {thinkingLevel = "low"; thinking_budget = 8192;};
          max = {thinkingLevel = "max"; thinking_budget = 32768;};
        };
      };
    };
  };
}
```

### Adding a New Model

1. Check upstream README: `https://github.com/NoeFabris/opencode-antigravity-auth#models`
2. Add the model attribute set following the pattern above
3. Match context_length, max_tokens, and modalities from upstream
4. Add thinking variants if the model supports them
5. Run `nix flake check --no-build` to verify

## Profile System

The `aiProfileHelpers.isWork` flag determines which profile to use:
- `true` → `workOverrides` (work environment)
- `false` → `personalOverrides` (personal environment)

Profile helpers are defined elsewhere in the Nix config and injected as a special argument.
