# Nix Core Concepts

Core Nix/NixOS concepts, terminology, and patterns used throughout the nix-config repository.

## Fundamental Concepts

### Nix Expression Language

Nix uses a pure, functional language for package definitions and system configurations:

```nix
# Basic types
string = "hello";
integer = 42;
float = 3.14;
boolean = true;
list = [1 2 3];
attributeSet = { key = "value"; };

# Functions
add = a: b: a + b;
add 1 2  # Returns 3

# Let expressions
let
  x = 1;
  y = 2;
in x + y  # Returns 3

# Conditionals
if condition then trueValue else falseValue

# Recursion (with rec)
rec {
  x = 1;
  y = x + 1;  # y = 2
}
```

### Derivation

A derivation is a recipe for building a package:

```nix
pkgs.stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "user";
    repo = "my-package";
    rev = "v1.0.0";
    sha256 = "...";
  };
  
  buildPhase = ''
    make
  '';
  
  installPhase = ''
    mkdir -p $out/bin
    cp my-package $out/bin/
  '';
}
```

### Evaluation vs. Realization

- **Evaluation**: Nix expression is parsed and evaluated to produce a derivation graph
- **Realization**: Derivation is built, producing output paths in `/nix/store`

## Nixpkgs

The Nix package collection is the central package set:

```nix
# Import nixpkgs
import <nixpkgs> {}

# Or with overlays
final: prev: {
  # Modify packages
}

# Access packages
pkgs.hello  # The hello package
pkgs.neovim  # Neovim

# All packages
pkgs ? import <nixpkgs> {}
```

### Package Build Functions

| Function | Use Case | Example |
|----------|----------|---------|
| `stdenv.mkDerivation` | Generic source builds | `mkDerivation { ... }` |
| `buildRustPackage` | Rust applications | `buildRustPackage { ... }` |
| `buildGoModule` | Go applications | `buildGoModule { ... }` |
| `buildPythonApplication` | Python applications | `buildPythonApplication { ... }` |
| `cmake.buildCMakePackage` | CMake projects | `cmake.buildCMakePackage { ... }` |
| `makeDesktopItem` | Desktop entries | `makeDesktopItem { ... }` |
| `vimUtils.buildVimPlugin` | Vim/Neovim plugins | `buildVimPlugin { ... }` |

## NixOS Modules

NixOS modules define system configuration:

```nix
{ config, pkgs, lib, ... }: {
  # Import other modules
  imports = [ ./hardware-configuration.nix ];
  
  # Define options
  options = {
    myModule.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable my module";
    };
  };
  
  # Configure based on options
  config = lib.mkIf config.myModule.enable {
    # Configuration goes here
    environment.systemPackages = with pkgs; [ vim ];
  };
}
```

### Module System Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `mkOption` | Define option | `mkOption { type = types.bool; }` |
| `mkEnableOption` | Boolean option helper | `mkEnableOption "feature"` |
| `mkDefault` | Set default value | `mkDefault true` |
| `mkIf` | Conditional config | `mkIf config.enable { ... }` |
| `mkWhen` | Conditional config (lazy) | `mkWhen isLinux { ... }` |
| `mkMerge` | Merge attr sets | `mkMerge [ a b c ]` |
| `mkForce` | Override default | `mkForce "value"` |

### Option Types

```nix
types.string          # "hello"
types.bool            # true/false
types.int             # 42
types.float           # 3.14
types.listOf types.str  # ["a" "b" "c"]
types.attrsOf types.str  # { key = "value"; }
types.enum ["a" "b"]  # "a" or "b"
types.path            # /path/to/file
types.package         # pkgs.hello
types.nullOr types.str  # null or "value"
```

## Home Manager

Home Manager manages user environment:

```nix
{ config, pkgs, lib, ... }: {
  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  
  programs.git = {
    enable = true;
    userName = "Jason";
    userEmail = "email@example.com";
  };
  
  home.packages = with pkgs; [ neovim ripgrep ];
  
  home.file.".config/nvim/init.lua".source = ./nvim/init.lua;
}
```

## Flakes

Flakes provide reproducible Nix expressions:

```nix
{
  description = "My flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, home-manager }: {
    # NixOS configurations
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
    
    # Home Manager configurations
    homeConfigurations = {
      "user@hostname" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [ ./home.nix ];
      };
    };
  };
}
```

### Flake Commands

```bash
# Evaluate flake
nix eval .#packages.x86_64-linux.hello

# Build package
nix build .#helium

# Run app
nix run .#neovim

# Update inputs
nix flake update

# Lock inputs
nix flake lock

# List inputs
nix flake list-inputs

# Show outputs
nix flake show
```

## Nix-Darwin

nix-darwin provides Nix-based macOS configuration:

```nix
{ config, pkgs, lib, ... }: {
  services.activate-global-shell = {
    enable = true;
    # Configuration
  };
  
  homebrew = {
    enable = true;
    brews = [
      "git"
      "neovim"
    ];
    casks = [
      "raycast"
      "visual-studio-code"
    ];
  };
}
```

## Common Patterns

### Overlays

Modify or extend packages:

```nix
# In overlays/default.nix
final: prev: {
  # Modify existing package
  neovim = prev.neovim.override {
    configure = {
      packages.myPlugin = with final.vimPlugins; builtins.fetchFromGitHub {
        # ...
      };
    };
  };
  
  # Add new package
  my-package = final.callPackage ../packages/my-package.nix {};
}
```

### Lib Helpers

Custom helpers in `lib/default.nix`:

```nix
# From the project
mkSystem = hostName: { system, user, ... }:
  nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [ ../hosts/${hostName}/configuration.nix ];
  };

mkHome = systemName: { system, ... }:
  home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs { inherit system; };
    modules = [ ../hosts/${systemName}/home.nix ];
  };
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `NIX_PATH` | Search path for `<nixpkgs>` |
| `NIX_CONF_DIR` | Nix configuration directory |
| `HOME` | User home directory |
| `XDG_RUNTIME_DIR` | Runtime directory for secrets |

## Common Errors

### Evaluation Errors

```
error: attribute 'foo' missing
# → Check spelling, imports

error: cannot call a function
# → Forgot parentheses around function

error: infinite recursion
# → Circular reference detected
```

### Build Errors

```
error: builder for 'x.nix' would have a result
# → Output already exists, use --impure or delete

error: hash mismatch
# → Incorrect sha256, update it

error: permission denied
# → Fix permissions or use sudo carefully
```

## Best Practices

1. **Use `lib.trivial.id` for identity functions**
2. **Prefer `mkIf` over `lib.optional` for conditional config**
3. **Use `lib.concatStringsSep` for string joining**
4. **Prefer `map` and `filter` over list comprehensions**
5. **Keep modules focused and small**
6. **Use imports for modularity**
7. **Document options with descriptions**
8. **Use `mkDefault` for sensible defaults**
9. **Test with `nix-instantiate` before building**
10. **Use `nix-shell` for development environments**
