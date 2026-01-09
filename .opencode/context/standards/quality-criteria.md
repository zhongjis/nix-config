# Quality Criteria

Quality standards and guidelines for all Nix modules, packages, and configurations.

## Module Quality Standards

### Required Elements

Every module must have:

```nix
{ pkgs, lib, config, ... }:

let
  cfg = config.myModule.feature;
in

{
  # 1. Meta information
  meta = {
    maintainers = with lib.maintainers; [ "zshen" ];
    # or
    # meta.maintainers = lib.maintainers.none;  # If no maintainer
  };
  
  # 2. Imports (if needed)
  imports = [
    # Dependency modules
  ];
  
  # 3. Options with descriptions
  options = myModule.feature = {
    enable = lib.mkEnableOption "feature description";
    
    # All options must have description
    setting = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Description of what this setting does";
    };
  };
  
  # 4. Configuration with mkIf
  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

### Option Standards

| Requirement | Description | Example |
|-------------|-------------|---------|
| **Description** | Every option must have a description | `description = "Enable feature";` |
| **Type** | Options should have explicit types | `type = types.str;` |
| **Default** | Provide sensible defaults | `default = true;` |
| **Enable option** | Use `mkEnableOption` for booleans | `lib.mkEnableOption "feature";` |

### Configuration Standards

```nix
# ✅ Good: Use mkIf for conditional config
config = lib.mkIf cfg.enable {
  service.enable = true;
};

# ❌ Bad: Runtime conditional
config = {
  service.enable = cfg.enable;  # Evaluates even when false
};

# ✅ Good: Use mkWhen for lazy evaluation
config = lib.mkWhen cfg.enable {
  service.enable = true;
};

# ✅ Good: Use optionalAttrs
config = {
  packages = [
    pkgs.hello
  ] ++ lib.optionalAttrs cfg.enableExtra [
    pkgs.world
  ];
};
```

### Import Standards

```nix
# ✅ Good: Clear imports
imports = [
  ../../common/module.nix
  ./submodule.nix
];

# ❌ Bad: Too many inline options
imports = [];

options = {
  # 100+ lines of options
};

# Better: Split into submodules
```

## Package Quality Standards

### Required Meta Fields

```nix
meta = with lib; {
  description = "Brief description of the package";
  homepage = "https://github.com/user/repo";
  license = licenses.mit;  # Must be accurate!
  maintainers = with maintainers; ["zshen"];
  
  # Platform support (optional but recommended)
  platforms = platforms.linux;  # or platforms.all
};
```

### Build Standards

```nix
# ✅ Good: Proper phases
stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";
  
  src = fetchFromGitHub { ... };
  
  nativeBuildInputs = [ autoconf automake ];
  buildInputs = [ libfoo ];
  
  buildPhase = ''
    ./configure --prefix=$out
    make
  '';
  
  installPhase = ''
    mkdir -p $out/bin
    cp my-package $out/bin/
  '';
  
  # ✅ Good: Tests
  doCheck = true;
  checkPhase = ''
    make test
  '';
};

# ❌ Bad: No proper phases
stdenv.mkDerivation {
  # Missing build/install phases
}
```

### Fetch Standards

```nix
# ✅ Good: SHA256 + immutable ref
src = fetchFromGitHub {
  owner = "user";
  repo = "my-package";
  rev = "v1.0.0";  # Immutable tag
  sha256 = "0000000000000000000000000000000000000000";
};

# ❌ Bad: Branch (changes!)
src = fetchFromGitHub {
  owner = "user";
  repo = "my-package";
  rev = "main";  # BAD: Changes!
  sha256 = "0000000000000000000000000000000000000000";
};
```

## Flake Quality Standards

### Input Standards

```nix
# ✅ Good: Proper input definition
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

# ✅ Good: Following inputs
home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";  # Auto-sync
};

# ❌ Bad: Outdated pin
nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";  # Old
```

### Output Standards

```nix
# ✅ Good: Well-structured outputs
outputs = { self, nixpkgs, ... }: {
  nixosConfigurations = {
    hostname = nixpkgs.lib.nixosSystem { ... };
  };
  
  packages = forAllSystems (pkgs: {
    my-package = import ./packages/my-package.nix { inherit pkgs; };
  });
};

# ❌ Bad: Missing outputs
outputs = { self, nixpkgs }: {
  # Only nixosConfigurations, no packages, no templates
};
```

## Code Style Standards

### Formatting

```nix
# ✅ Good: Proper indentation (2 spaces)
{
  options = {
    myModule = {
      enable = lib.mkEnableOption "my module";
    };
  };
}

# ❌ Bad: Inconsistent indentation
{
options = {
myModule = {
    enable = lib.mkEnableOption "my module";
};
}
}
```

### Naming Conventions

```nix
# ✅ Good: Consistent naming
options = myModule.feature = {
  enable = lib.mkEnableOption "feature";
  package = lib.mkOption { ... };
};

config = lib.mkIf config.myModule.feature.enable {
  # Configuration
};

# ❌ Bad: Inconsistent naming
options = mymodule = {
  enabled = lib.mkEnableOption "mymodule";  # Different naming
};

config = {
  mymodule.enabled = true;  # Different naming
};
```

### Line Length

- **Soft limit**: 100 characters
- **Hard limit**: 150 characters (rare exceptions)

```nix
# ✅ Good: Readable line length
programs.git = {
  userName = "Jason Shen";
  userEmail = "email@example.com";
};

# ✅ Good: Split long lines
programs.neovim = {
  enable = true;
  plugins = with pkgs.vimPlugins; [
    nvim-cmp
    LSP
    Telescope
    Treesitter
  ];
};
```

### Comments

```nix
# ✅ Good: Descriptive comments
# Enable GPU monitoring for AMD cards
services.amdgpu.enable = true;

# ❌ Bad: Unhelpful comments
# This enables the service
services.amdgpu.enable = true;
```

## Documentation Standards

### Module Documentation

```nix
{ lib, ... }:

{
  # ✅ Good: Documentation at top
  meta = {
    doc = ''
      # My Module
      
      This module provides X functionality for Y.
      
      ## Usage
      
      Enable in configuration:
      
      ```nix
      myModule.feature.enable = true;
      ```
      
      ## Options
      
      - `enable`: Enable the feature
      - `setting`: Configure behavior
    '';
  };
}
```

### README Updates

When adding new features, update README:

```markdown
## Features

### My New Feature

Description of what it does.

```nix
myModule.feature.enable = true;
```
```

## Validation Checklist

### Module Validation
- [ ] All options have descriptions
- [ ] All options have types
- [ ] Boolean options use `mkEnableOption`
- [ ] Configuration uses `mkIf`/`mkWhen`
- [ ] No runtime conditionals
- [ ] Meta maintainers set

### Package Validation
- [ ] Meta fields complete (description, license, homepage)
- [ ] Proper fetch with SHA256
- [ ] Immutable ref (tag/commit, not branch)
- [ ] Build phases defined
- [ ] Platform support specified

### Flake Validation
- [ ] All inputs have URLs
- [ ] Follows relationships correct
- [ ] Outputs well-structured
- [ ] Evaluates successfully
- [ ] All systems build

## Quality Score

Rate modules on scale 1-10:

| Score | Description |
|-------|-------------|
| **9-10** | Perfect, no improvements needed |
| **7-8** | Good, minor improvements possible |
| **5-6** | Functional, needs some work |
| **3-4** | Needs significant improvement |
| **1-2** | Poor quality, rewrite recommended |

### Target: All modules ≥ 7/10
