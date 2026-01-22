# Implementation Plan: Migrate nix-config-private to flake-parts

**Goal:** Migrate `nix-config-private` repository to use flake-parts pattern matching the main `nix-config` repo, with graceful sops key handling for bootstrap scenarios.

**Status:** Ready for implementation  
**Estimated Complexity:** Medium (4-6 hours)  
**Breaking Changes:** Yes, but backward compatible outputs maintained

---

## Table of Contents

1. [Context & Requirements](#context--requirements)
2. [Architecture Design](#architecture-design)
3. [Implementation Phases](#implementation-phases)
4. [File-by-File Changes](#file-by-file-changes)
5. [Testing Strategy](#testing-strategy)
6. [Rollback Plan](#rollback-plan)

---

## Context & Requirements

### Current Problem

**Bootstrap Failure:** When setting up a new machine, the build fails because:
1. `home-manager switch` runs for the first time
2. Private modules require sops secrets from `secrets/adobe.yaml`
3. sops-nix tries to decrypt using `~/.config/sops/age/keys.txt`
4. **Key doesn't exist yet** (should be provisioned by HM, but HM can't complete)
5. Build fails, creating a chicken-and-egg problem

### User Requirements

1. ✅ Keep existing namespace: `zshen-private-flake.adobe-marketo-flex`
2. ✅ Use work-profile bundles organization (Option B)
3. ✅ Support future additions: NixOS/Darwin modules, packages, overlays
4. ✅ Graceful degradation when sops age key is missing
5. ✅ Maintain backward compatibility with existing integration

### Research Summary

**From librarian research:**
- flake-parts provides `flake.nixosModules`, `flake.darwinModules`, `flake.homeModules`
- Auto-discovery with `import-tree` matches main repo pattern
- Multiple export strategies: `default` + named bundles
- Conditional loading via `lib.mkIf` with enable flags

**From sops-nix research:**
- sops-nix enforces assertions requiring at least one key source
- Best practice: Enable flag with `lib.mkDefault true` + `lib.mkIf` wrapper
- Bootstrap solution: `sops.age.generateKey = true` OR `validateSopsFiles = false`
- Conditional module loading prevents evaluation errors

---

## Architecture Design

### New Directory Structure

```
nix-config-private/
├── flake.nix                              # ← UPDATED: Use flake-parts
├── flake.lock                             # ← Regenerated
├── flake-parts/                           # ← NEW
│   ├── modules.nix                        # ← NEW: Auto-discover & expose modules
│   ├── overlays.nix                       # ← NEW: Future private overlays
│   └── packages.nix                       # ← NEW: Future private packages
├── lib/                                   # ← NEW: Helper functions (optional)
│   └── default.nix                        # ← NEW: Shared utilities
├── modules/
│   ├── home-manager/                      # ← RENAMED from adobe-marketo-flex
│   │   ├── default.nix                    # ← NEW: Entry point, imports bundles
│   │   ├── bundles/                       # ← NEW: Work profile bundles
│   │   │   ├── adobe-work.nix             # ← NEW: Adobe Marketo Flex bundle
│   │   │   └── google-work.nix            # ← NEW: Placeholder for future
│   │   └── features/                      # ← NEW: Individual feature modules
│   │       └── adobe-marketo-flex/        # ← MOVED from ../
│   │           ├── default.nix            # ← UPDATED: Namespace, enable logic
│   │           ├── git.nix                # ← UPDATED: Conditional loading
│   │           ├── ssh.nix                # ← UPDATED: Conditional sops
│   │           ├── sbt.nix                # ← UPDATED: Conditional sops
│   │           ├── mvn.nix                # ← UPDATED: Conditional sops
│   │           └── zsh/
│   │               ├── default.nix        # ← UPDATED: Conditional sops
│   │               └── balabit.sh         # ← UNCHANGED
│   ├── nixos/                             # ← NEW: Future NixOS modules
│   │   └── .gitkeep                       # ← NEW
│   └── darwin/                            # ← NEW: Future Darwin modules
│       └── .gitkeep                       # ← NEW
├── overlays/                              # ← NEW: Future private overlays
│   └── default.nix                        # ← NEW
├── packages/                              # ← NEW: Future private packages
│   └── .gitkeep                           # ← NEW
├── secrets/                               # ← UNCHANGED
│   ├── adobe-marketo-campaign.yaml
│   └── adobe.yaml
├── .sops.yaml                             # ← UNCHANGED
├── .gitignore                             # ← UNCHANGED
└── README.md                              # ← UPDATED: New structure docs
```

### Module Organization Philosophy

**Bundles = Work Profiles:**
- `bundles/adobe-work.nix` - Enables all Adobe Marketo Flex features
- `bundles/google-work.nix` - (Future) Google workspace features
- Easy to toggle entire work profiles on/off

**Features = Granular Components:**
- `features/adobe-marketo-flex/*` - Specific tool configurations
- Can be used independently if needed
- Each feature handles its own sops gracefully

### Output Strategy

**Multiple export patterns for flexibility:**

```nix
flake.homeModules = {
  # Primary output - backward compatible
  zshen-nix-config-private = [ ./modules/home-manager ];
  
  # Alias for convenience
  default = [ ./modules/home-manager ];
  
  # Granular bundles - cherry-pick what you need
  bundles = {
    adobe-work = [ ./modules/home-manager/bundles/adobe-work.nix ];
    google-work = [ ./modules/home-manager/bundles/google-work.nix ];
  };
  
  # Individual features - maximum flexibility
  features = {
    adobe-marketo-flex = [ ./modules/home-manager/features/adobe-marketo-flex ];
  };
};
```

**Usage examples:**

```nix
# Option 1: All modules (current approach, backward compatible)
imports = [
  inputs.nix-config-private.homeModules.zshen-nix-config-private
];

# Option 2: Use default alias
imports = [
  inputs.nix-config-private.homeModules.default
];

# Option 3: Cherry-pick specific bundle
imports = [
  inputs.nix-config-private.homeModules.bundles.adobe-work
];

# Option 4: Individual feature
imports = [
  inputs.nix-config-private.homeModules.features.adobe-marketo-flex
];
```

### Sops Graceful Degradation Strategy

**Three-layer defense:**

1. **Layer 1: Enable flag at bundle level**
   ```nix
   # bundles/adobe-work.nix
   myPrivate.bundles.adobe-work.enable = lib.mkDefault true;
   ```

2. **Layer 2: Conditional feature imports**
   ```nix
   # features/adobe-marketo-flex/default.nix
   config = lib.mkIf cfg.enable {
     # All sops secrets wrapped in mkIf
   };
   ```

3. **Layer 3: Validate sops key existence**
   ```nix
   # Check if key exists before loading secrets
   hasSopsKey = builtins.pathExists "${config.home.homeDirectory}/.config/sops/age/keys.txt";
   
   sops.secrets = lib.mkIf hasSopsKey {
     # Define secrets only if key exists
   };
   ```

**Alternative: Auto-generate key**
```nix
sops.age = {
  generateKey = true;  # Creates key on first run
  keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
};
```

---

## Implementation Phases

### Phase 1: Add flake-parts Infrastructure

**Objective:** Set up flake-parts foundation without breaking existing functionality.

**Changes:**
1. Update `flake.nix` to add `flake-parts` and `import-tree` inputs
2. Create `flake-parts/` directory structure
3. Create initial `flake-parts/modules.nix`
4. Create placeholder `flake-parts/overlays.nix` and `flake-parts/packages.nix`
5. Update flake outputs to use `flake-parts.lib.mkFlake`
6. **Maintain** existing `homeModules.zshen-nix-config-private` output

**Success criteria:**
- `nix flake check` passes
- `nix flake show` displays all outputs correctly
- Existing integration in main repo still works

**Estimated time:** 1 hour

---

### Phase 2: Restructure Module Directory

**Objective:** Reorganize modules to bundle pattern while maintaining functionality.

**Changes:**
1. Create `modules/home-manager/` directory structure
2. Create `modules/home-manager/bundles/adobe-work.nix`
3. Move `modules/adobe-marketo-flex/` → `modules/home-manager/features/adobe-marketo-flex/`
4. Create `modules/home-manager/default.nix` as entry point
5. Update import paths in all moved files
6. Create `.gitkeep` files for future directories

**Success criteria:**
- All modules importable from new locations
- No broken imports
- Build completes successfully

**Estimated time:** 1 hour

---

### Phase 3: Implement Graceful Sops Handling

**Objective:** Add conditional logic to prevent bootstrap failures.

**Changes:**
1. Add enable option to `adobe-work.nix` bundle
2. Update `features/adobe-marketo-flex/default.nix` with conditional wrapper
3. Add `hasSopsKey` check to each feature module
4. Wrap all `sops.secrets` definitions in `lib.mkIf hasSopsKey`
5. Add helpful warnings when key is missing
6. Update bundle to pass sops availability to features

**Success criteria:**
- Build succeeds when sops key is missing
- Build succeeds when sops key is present
- Secrets only loaded when key exists
- Clear warning messages guide users

**Estimated time:** 2 hours

---

### Phase 4: Update Main Repo Integration

**Objective:** Verify integration and update documentation.

**Changes:**
1. Test existing import still works
2. Update main repo docs to reference new structure
3. Add usage examples for new import patterns
4. Test on fresh machine without sops key
5. Verify secrets load correctly with key present

**Success criteria:**
- Main repo builds successfully
- Private modules load correctly
- Bootstrap scenario works
- Documentation is accurate

**Estimated time:** 1 hour

---

### Phase 5: Add Future-Proof Exports

**Objective:** Set up exports for packages, overlays, and other module types.

**Changes:**
1. Create `overlays/default.nix` with empty overlay
2. Create `packages/` structure
3. Update `flake-parts/packages.nix` to expose per-system packages
4. Add `nixosModules` and `darwinModules` outputs
5. Update README with extension guide

**Success criteria:**
- `nix flake show` displays all output types
- Structure ready for future additions
- Clear documentation on adding new components

**Estimated time:** 30 minutes

---

## File-by-File Changes

### 1. `flake.nix`

**Before:**
```nix
{
  description = "Private configurations for zshen's Nix setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    sops-nix,
  }: let
    lib = nixpkgs.lib;
    privateModules = [
      {
        imports = [
          ./modules/adobe-marketo-flex
          sops-nix.homeManagerModules.sops
        ];
        _module.args = {inherit inputs;};
      }
    ];
  in {
    homeModules.zshen-nix-config-private = privateModules;
  };
}
```

**After:**
```nix
{
  description = "Private configurations for zshen's Nix setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./flake-parts/modules.nix
        ./flake-parts/overlays.nix
        ./flake-parts/packages.nix
      ];
    };
}
```

---

### 2. `flake-parts/modules.nix` (NEW)

```nix
{ inputs, lib, ... }:
let
  tree = inputs.import-tree.withLib lib;

  # Helper to discover and convert to attrset
  discoverModules = dir:
    let
      files = (tree.addPath dir).files;
    in
    lib.listToAttrs (
      map
        (path: {
          name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
          value = path;
        })
        files
    );

  # Private modules with sops-nix integration
  homeManagerModules = [
    {
      imports = [
        ./modules/home-manager
        inputs.sops-nix.homeManagerModules.sops
      ];
      _module.args = {inherit inputs;};
    }
  ];
in
{
  flake = {
    # Home Manager modules - multiple export patterns
    homeModules = {
      # Primary output - backward compatible
      zshen-nix-config-private = homeManagerModules;
      
      # Alias for convenience
      default = homeManagerModules;
      
      # Granular bundles - cherry-pick what you need
      bundles = {
        adobe-work = [
          {
            imports = [
              ./modules/home-manager/bundles/adobe-work.nix
              inputs.sops-nix.homeManagerModules.sops
            ];
            _module.args = {inherit inputs;};
          }
        ];
        # Future: google-work, etc.
      };
      
      # Individual features - maximum flexibility
      features = {
        adobe-marketo-flex = [
          {
            imports = [
              ./modules/home-manager/features/adobe-marketo-flex
              inputs.sops-nix.homeManagerModules.sops
            ];
            _module.args = {inherit inputs;};
          }
        ];
      };
    };

    # Future: NixOS modules
    nixosModules = {
      default = ./modules/nixos;
    };

    # Future: Darwin modules
    darwinModules = {
      default = ./modules/darwin;
    };
  };
}
```

---

### 3. `flake-parts/overlays.nix` (NEW)

```nix
{ inputs, ... }:
{
  flake.overlays = {
    # Future: Add private package overlays here
    default = final: prev: {
      # Example:
      # my-private-tool = final.callPackage ../packages/my-private-tool.nix { };
    };
  };
}
```

---

### 4. `flake-parts/packages.nix` (NEW)

```nix
{ inputs, ... }:
{
  perSystem = {
    config,
    pkgs,
    lib,
    system,
    ...
  }: {
    packages = {
      # Future: Add private packages here
      # Example:
      # my-tool = pkgs.callPackage ../packages/my-tool.nix { };
    };
  };
}
```

---

### 5. `modules/home-manager/default.nix` (NEW)

```nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./bundles/adobe-work.nix
    # Future: ./bundles/google-work.nix
  ];

  # No default configuration here - bundles control their own enable flags
}
```

---

### 6. `modules/home-manager/bundles/adobe-work.nix` (NEW)

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myPrivate.bundles.adobe-work;
in {
  options.myPrivate.bundles.adobe-work = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Adobe Marketo Flex work profile bundle";
    };
  };

  config = lib.mkIf cfg.enable {
    # Import all Adobe Marketo Flex features
    imports = [
      ../features/adobe-marketo-flex
    ];

    # Enable the adobe-marketo-flex feature
    zshen-private-flake.adobe-marketo-flex.enable = true;
  };
}
```

---

### 7. `modules/home-manager/features/adobe-marketo-flex/default.nix` (UPDATED)

**Before:**
```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
in {
  imports = [
    ./zsh
    ./git.nix
    ./sbt.nix
    ./ssh.nix
  ];

  options.zshen-private-flake.adobe-marketo-flex = {
    enable = lib.mkOption {
      description = "Adobe-specific private configurations";
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Configuration will be applied from the imported modules above
  };
}
```

**After:**
```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  
  # Check if sops age key exists to gracefully handle bootstrap
  hasSopsKey = builtins.pathExists "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in {
  imports = [
    ./zsh
    ./git.nix
    ./sbt.nix
    ./ssh.nix
    ./mvn.nix
  ];

  options.zshen-private-flake.adobe-marketo-flex = {
    enable = lib.mkOption {
      description = "Adobe Marketo Flex work profile configuration";
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Warn if sops key is missing (not an error, just informational)
    warnings = lib.optional (!hasSopsKey) ''
      sops age key not found at ~/.config/sops/age/keys.txt
      Adobe Marketo Flex secrets will not be available.
      To provision: Generate age key and add to secrets/adobe.yaml
    '';

    # Pass hasSopsKey to submodules via _module.args
    _module.args = {
      inherit hasSopsKey;
    };
  };
}
```

---

### 8. `modules/home-manager/features/adobe-marketo-flex/git.nix` (UPDATED)

**Before:**
```nix
{
  lib,
  config,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
in {
  config = lib.mkIf cfg.enable {
    programs.git = {
      settings.user = {
        name = lib.mkForce "zshen";
        email = lib.mkForce "zshen@adobe.com";
      };
    };
  };
}
```

**After (no changes needed - doesn't use secrets):**
```nix
{
  lib,
  config,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
in {
  config = lib.mkIf cfg.enable {
    programs.git = {
      settings.user = {
        name = lib.mkForce "zshen";
        email = lib.mkForce "zshen@adobe.com";
      };
    };
  };
}
```

---

### 9. `modules/home-manager/features/adobe-marketo-flex/ssh.nix` (UPDATED)

**Before:**
```nix
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  darwinKeychainOption =
    if pkgs.stdenv.isDarwin
    then {
      UseKeychain = "yes";
    }
    else {};
  ADBUSER = "zshen";
  sopsFile = ../../secrets/adobe.yaml;
in {
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      # github - adobe
      "ssh/github_adobe_zshen/private_key" = {
        path = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
        inherit sopsFile;
      };
      # ... more secrets ...
    };

    programs.ssh.matchBlocks = {
      # ... SSH config ...
    };
  };
}
```

**After:**
```nix
{
  pkgs,
  config,
  lib,
  hasSopsKey ? false,  # Passed from parent module
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  darwinKeychainOption =
    if pkgs.stdenv.isDarwin
    then {
      UseKeychain = "yes";
    }
    else {};
  ADBUSER = "zshen";
  sopsFile = ../../../../secrets/adobe.yaml;  # Updated path after move
in {
  config = lib.mkIf cfg.enable {
    # Only define secrets if sops key is available
    sops.secrets = lib.mkIf hasSopsKey {
      # github - adobe
      "ssh/github_adobe_zshen/private_key" = {
        path = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
        inherit sopsFile;
      };
      "ssh/github_adobe_zshen/public_key" = {
        path = "${config.home.homeDirectory}/.ssh/github_adobe_zshen.pub";
        inherit sopsFile;
      };

      # liveaccess - adobe
      "ssh/iam/private_key" = {
        path = "${config.home.homeDirectory}/.ssh/liveaccess_adobe_zshen";
        inherit sopsFile;
      };
      "ssh/iam/public_key" = {
        path = "${config.home.homeDirectory}/.ssh/liveaccess_adobe_zshen.pub";
        inherit sopsFile;
      };
    };

    # SSH config always applied (will reference secrets if available)
    programs.ssh.matchBlocks = {
      "github.com-zshen_adobe" = {
        host = "github.com-zshen_adobe";
        hostname = "github.com";
        identityFile = "${config.home.homeDirectory}/.ssh/github_adobe_zshen";
        identitiesOnly = true;
        extraOptions = let
          baseOptions = {
            PreferredAuthentications = "publickey";
          };
        in
          baseOptions // darwinKeychainOption;
      };
      # ... rest of SSH config (unchanged) ...
    };
  };
}
```

---

### 10. `modules/home-manager/features/adobe-marketo-flex/sbt.nix` (UPDATED)

**Before:**
```nix
{
  config,
  lib,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../secrets/adobe.yaml;
in {
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "uw2-it-artifactory-api-token" = {
        inherit sopsFile;
      };
      "corp-artifactory-api-token" = {
        inherit sopsFile;
      };
    };

    programs.sbt = {
      enable = lib.mkDefault true;
      credentials = [
        {
          realm = "Artifactory Realm";
          user = "zshen";
          passwordCommand = "cat ${config.sops.secrets."corp-artifactory-api-token".path}";
          host = "artifactory.corp.adobe.com";
        }
        # ... more credentials ...
      ];
    };
  };
}
```

**After:**
```nix
{
  config,
  lib,
  hasSopsKey ? false,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../../../secrets/adobe.yaml;  # Updated path
in {
  config = lib.mkIf cfg.enable {
    # Only define secrets if sops key is available
    sops.secrets = lib.mkIf hasSopsKey {
      "uw2-it-artifactory-api-token" = {
        inherit sopsFile;
      };
      "corp-artifactory-api-token" = {
        inherit sopsFile;
      };
    };

    # Only enable SBT if secrets are available
    programs.sbt = lib.mkIf hasSopsKey {
      enable = lib.mkDefault true;
      credentials = [
        {
          realm = "Artifactory Realm";
          user = "zshen";
          passwordCommand = "cat ${config.sops.secrets."corp-artifactory-api-token".path}";
          host = "artifactory.corp.adobe.com";
        }
        {
          realm = "Artifactory Realm";
          user = "zshen";
          passwordCommand = "cat ${config.sops.secrets."uw2-it-artifactory-api-token".path}";
          host = "artifactory-uw2.adobeitc.com";
        }
      ];
    };
  };
}
```

---

### 11. `modules/home-manager/features/adobe-marketo-flex/mvn.nix` (UPDATED)

**Before:**
```nix
{
  config,
  lib,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../secrets/adobe.yaml;
  username = "zshen";
in {
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "uw2-it-artifactory-api-token" = {
        inherit sopsFile;
      };
      "corp-artifactory-api-token" = {
        inherit sopsFile;
      };
    };

    home.file.".m2/settings.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" ...>
         ...
         <password>${builtins.readFile config.sops.secrets."uw2-it-artifactory-api-token".path}</password>
         ...
      </settings>
    '';
  };
}
```

**After:**
```nix
{
  config,
  lib,
  hasSopsKey ? false,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../../../secrets/adobe.yaml;  # Updated path
  username = "zshen";
in {
  config = lib.mkIf cfg.enable {
    # Only define secrets if sops key is available
    sops.secrets = lib.mkIf hasSopsKey {
      "uw2-it-artifactory-api-token" = {
        inherit sopsFile;
      };
      "corp-artifactory-api-token" = {
        inherit sopsFile;
      };
    };

    # Only create settings.xml if secrets are available
    home.file.".m2/settings.xml" = lib.mkIf hasSopsKey {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
           <interactiveMode>false</interactiveMode>
           <mirrors>
              <mirror>
                 <id>central-artifactory</id>
                 <name>Artifactory Central</name>
                 <url>https://artifactory.corp.adobe.com/artifactory/central-maven-remote</url>
                 <mirrorOf>central</mirrorOf>
              </mirror>
           </mirrors>
           <servers>
              <server>
               <id>artifactory-uw2.adobeitc.com</id>
               <username>${username}</username>
               <password>${builtins.readFile config.sops.secrets."uw2-it-artifactory-api-token".path}</password>
              </server>
              <server>
                  <id>asr-releases</id>
                  <username>${username}</username>
                  <password>${builtins.readFile config.sops.secrets."corp-artifactory-api-token".path}</password>
              </server>
              <server>
                <id>asr-snapshots</id>
                <username>${username}</username>
                <password>${builtins.readFile config.sops.secrets."corp-artifactory-api-token".path}</password>
              </server>
              <server>
                  <id>central-artifactory</id>
                  <username>${username}</username>
                  <password>${builtins.readFile config.sops.secrets."corp-artifactory-api-token".path}</password>
              </server>
           </servers>
           <profiles>
              <profile>
                 <id>default</id>
                 <activation>
                    <activeByDefault>true</activeByDefault>
                 </activation>
                 <properties>
                    <maven.test.failure.ignore>false</maven.test.failure.ignore>
                 </properties>
                 <pluginRepositories>
                     <pluginRepository>
                        <id>asr-releases</id>
                        <url>https://artifactory.corp.adobe.com/artifactory/maven-asr-release</url>
                    </pluginRepository>
                    <pluginRepository>
                       <id>central-artifactory</id>
                       <url>https://artifactory.corp.adobe.com/artifactory/central-maven-remote</url>
                    </pluginRepository>
                 </pluginRepositories>
                 <repositories>
                    <repository>
                        <id>asr-releases</id>
                        <name>ASR Releases</name>
                        <url>https://artifactory.corp.adobe.com/artifactory/maven-asr-release</url>
                        <snapshots>
                            <enabled>false</enabled>
                        </snapshots>
                        <releases>
                            <enabled>true</enabled>
                            <updatePolicy>always</updatePolicy>
                        </releases>
                    </repository>
                    <repository>
                       <id>asr-snapshots</id>
                       <name>ASR Snapshots</name>
                       <url>https://artifactory.corp.adobe.com/artifactory/maven-asr-snapshot</url>
                       <snapshots>
                          <enabled>true</enabled>
                       </snapshots>
                    </repository>
                 </repositories>
              </profile>
           </profiles>
        </settings>
      '';
    };
  };
}
```

---

### 12. `modules/home-manager/features/adobe-marketo-flex/zsh/default.nix` (UPDATED)

**Before:**
```nix
{
  config,
  lib,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../../secrets/adobe.yaml;
in {
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "ldap" = { inherit sopsFile; };
      "uw2-it-artifactory-api-token" = { inherit sopsFile; };
      "corp-artifactory-api-token" = { inherit sopsFile; };
      "campaign/env/USER_MKTODEV_PASSWORD" = { inherit sopsFile; };
    };
    
    programs.zsh = lib.mkIf config.programs.zsh.enable {
      envExtra = ''
        export ARTIFACTORY_USER="$(cat ${config.sops.secrets."ldap".path})";
        # ... more exports ...
      '';

      initContent = lib.mkOrder 1000 ''
        source "${./balabit.sh}"
      '';
    };
  };
}
```

**After:**
```nix
{
  config,
  lib,
  hasSopsKey ? false,
  ...
}: let
  cfg = config.zshen-private-flake.adobe-marketo-flex;
  sopsFile = ../../../../../secrets/adobe.yaml;  # Updated path
in {
  config = lib.mkIf cfg.enable {
    # Only define secrets if sops key is available
    sops.secrets = lib.mkIf hasSopsKey {
      "ldap" = { inherit sopsFile; };
      "uw2-it-artifactory-api-token" = { inherit sopsFile; };
      "corp-artifactory-api-token" = { inherit sopsFile; };
      "campaign/env/USER_MKTODEV_PASSWORD" = { inherit sopsFile; };
    };
    
    programs.zsh = lib.mkIf config.programs.zsh.enable {
      # Conditionally set environment variables based on secret availability
      envExtra = lib.mkIf hasSopsKey ''
        # ARTIFACTORY CORP
        export ARTIFACTORY_USER="$(cat ${config.sops.secrets."ldap".path})";
        export ARTIFACTORY_API_TOKEN="$(cat ${config.sops.secrets."corp-artifactory-api-token".path})"

        # ARTIFACTORY CLOUD
        export ARTIFACTORY_UW2_USER="$(cat ${config.sops.secrets."ldap".path})";
        export ARTIFACTORY_UW2_API_TOKEN="$(cat ${config.sops.secrets."uw2-it-artifactory-api-token".path})"

        export USER_MKTODEV_PASSWORD="$(cat ${config.sops.secrets."campaign/env/USER_MKTODEV_PASSWORD".path})"
      '' + ''
        # NOTE: for tmux sessionizer (always set)
        export SESSIONIZER_PATHS="$HOME/.config $HOME/personal $HOME/work $HOME/Library/CloudStorage/OneDrive-Adobe"
      '';

      # Always source balabit helper
      initContent = lib.mkOrder 1000 ''
        source "${./balabit.sh}"
      '';
    };
  };
}
```

---

### 13. Update main repo integration (hosts/mac-m1-max/home.nix)

**Before:**
```nix
{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports =
    [
      ../../modules/home-manager
      ../../modules/home-manager-darwin
    ]
    ++ inputs.nix-config-private.homeModules.zshen-nix-config-private;

  zshen-private-flake.adobe-marketo-flex.enable = true;

  # ... rest of config ...
}
```

**After (multiple options):**

```nix
{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports =
    [
      ../../modules/home-manager
      ../../modules/home-manager-darwin
    ]
    # Option 1: Keep existing (backward compatible)
    ++ inputs.nix-config-private.homeModules.zshen-nix-config-private;
    
    # Option 2: Use bundle directly (recommended for new approach)
    # ++ inputs.nix-config-private.homeModules.bundles.adobe-work;
    
    # Option 3: Use default alias
    # ++ inputs.nix-config-private.homeModules.default;

  # If using bundle import (Option 2), enable the bundle:
  # myPrivate.bundles.adobe-work.enable = true;
  
  # If using traditional import (Option 1), keep existing:
  zshen-private-flake.adobe-marketo-flex.enable = true;

  # ... rest of config ...
}
```

---

### 14. `README.md` (UPDATED)

```markdown
# nix-config-private

Private work-related configurations for zshen's Nix setup.

## Structure

```
nix-config-private/
├── flake-parts/          # Flake-parts modules
│   ├── modules.nix       # Module discovery and exports
│   ├── overlays.nix      # Private package overlays
│   └── packages.nix      # Private packages
├── modules/
│   ├── home-manager/     # Home Manager modules
│   │   ├── bundles/      # Work profile bundles
│   │   └── features/     # Individual features
│   ├── nixos/            # NixOS modules (future)
│   └── darwin/           # Darwin modules (future)
└── secrets/              # Encrypted secrets (sops-nix)
```

## Usage

### Import All Modules (Traditional)

```nix
{
  inputs.nix-config-private.url = "git+ssh://git@github.com/zhongjis/nix-config-private.git";
}

# In home-manager config:
{
  imports = inputs.nix-config-private.homeModules.zshen-nix-config-private;
  zshen-private-flake.adobe-marketo-flex.enable = true;
}
```

### Import Specific Bundle (Recommended)

```nix
{
  imports = inputs.nix-config-private.homeModules.bundles.adobe-work;
  myPrivate.bundles.adobe-work.enable = true;
}
```

### Import Individual Feature

```nix
{
  imports = inputs.nix-config-private.homeModules.features.adobe-marketo-flex;
  zshen-private-flake.adobe-marketo-flex.enable = true;
}
```

## Bootstrap Without Secrets

On first setup, you may not have the sops age key yet. The modules gracefully handle this:

1. Build will complete without secrets
2. Warning message will guide you to provision the key
3. After key is provisioned, rebuild to enable secrets

## Adding New Work Profiles

1. Create bundle: `modules/home-manager/bundles/company-work.nix`
2. Create features: `modules/home-manager/features/company-xyz/`
3. Update `flake-parts/modules.nix` to export the new bundle
4. Enable in your host configuration

## Secret Management

Uses sops-nix with age encryption. Key location: `~/.config/sops/age/keys.txt`

To view secrets:
```bash
nix run nixpkgs#sops -- secrets/adobe.yaml
```

To edit secrets:
```bash
nix run nixpkgs#sops -- secrets/adobe.yaml
```

## License

Private repository - not for public use.
```

---

## Testing Strategy

### Pre-Migration Tests

1. **Baseline verification:**
   ```bash
   cd ~/personal/nix-config-private
   nix flake check
   nix flake show
   ```

2. **Integration test:**
   ```bash
   cd ~/personal/nix-config
   nh darwin switch .  # Should succeed
   ```

### Phase-by-Phase Tests

**After Phase 1 (flake-parts infrastructure):**
```bash
cd ~/personal/nix-config-private
nix flake check
nix flake show  # Verify all outputs visible
nix eval .#homeModules.zshen-nix-config-private  # Should evaluate
```

**After Phase 2 (directory restructure):**
```bash
cd ~/personal/nix-config-private
nix flake check
# Verify all imports resolve:
nix eval .#homeModules.zshen-nix-config-private --show-trace
nix eval .#homeModules.bundles.adobe-work --show-trace
```

**After Phase 3 (graceful sops):**
```bash
# Test WITHOUT sops key:
cd ~/personal/nix-config-private
mv ~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt.backup
nix flake check  # Should succeed with warnings

# Test WITH sops key:
mv ~/.config/sops/age/keys.txt.backup ~/.config/sops/age/keys.txt
nix flake check  # Should succeed with no warnings
```

**After Phase 4 (integration):**
```bash
cd ~/personal/nix-config
# Test build:
nix build .#darwinConfigurations.Zs-MacBook-Pro.system --show-trace
# Test activation:
nh darwin switch . --dry-run
nh darwin switch .
```

### Final Validation Checklist

- [ ] `nix flake check` passes in private repo
- [ ] `nix flake show` displays all outputs
- [ ] Build succeeds WITHOUT sops key (with warnings)
- [ ] Build succeeds WITH sops key (no warnings)
- [ ] Main repo builds successfully
- [ ] Secrets load correctly when key present
- [ ] SSH config applied correctly
- [ ] Maven/SBT credentials work
- [ ] Zsh environment variables set correctly
- [ ] Documentation is accurate

---

## Rollback Plan

### Quick Rollback (Git-based)

1. **Before starting:**
   ```bash
   cd ~/personal/nix-config-private
   git checkout -b migrate-to-flake-parts
   git push -u origin migrate-to-flake-parts
   ```

2. **If issues arise:**
   ```bash
   cd ~/personal/nix-config-private
   git checkout main
   git reset --hard origin/main
   ```

3. **In main repo:**
   ```bash
   cd ~/personal/nix-config
   nix flake lock --update-input nix-config-private
   nh darwin switch .
   ```

### Partial Rollback (Phase-specific)

If a specific phase fails, you can rollback to the previous phase:

```bash
# Show commits in current branch:
git log --oneline

# Rollback to specific phase:
git reset --hard <commit-hash-from-previous-phase>
```

### Complete Rollback (Nuclear Option)

If everything breaks:

```bash
cd ~/personal/nix-config-private
git checkout main
git branch -D migrate-to-flake-parts
git fetch origin
git reset --hard origin/main

cd ~/personal/nix-config
nix flake lock --update-input nix-config-private
nh darwin switch .
```

---

## Risk Assessment

### High Risk Items

1. **Secret path references changing:**
   - **Risk:** `sopsFile = ../../secrets/adobe.yaml` becomes incorrect after move
   - **Mitigation:** Test each module's secret loading after move
   - **Detection:** Build will fail with "file not found"

2. **Missing sops key on existing system:**
   - **Risk:** Accidentally breaking working system
   - **Mitigation:** Test on non-production branch first
   - **Detection:** Secrets won't decrypt, services fail

3. **Import path cycles:**
   - **Risk:** Circular imports after restructure
   - **Mitigation:** Careful planning of import structure
   - **Detection:** Nix evaluation will fail with "infinite recursion"

### Medium Risk Items

1. **Backward compatibility:**
   - **Risk:** Main repo integration breaks
   - **Mitigation:** Maintain `homeModules.zshen-nix-config-private` output
   - **Detection:** Main repo build fails

2. **Missing conditional logic:**
   - **Risk:** Some modules still require secrets
   - **Mitigation:** Thorough review of all modules
   - **Detection:** Build fails on fresh system

### Low Risk Items

1. **Documentation inaccuracy:**
   - **Risk:** README doesn't match implementation
   - **Mitigation:** Update docs as you go
   - **Detection:** Manual review

2. **Git merge conflicts:**
   - **Risk:** Conflicts during merge to main
   - **Mitigation:** Work in feature branch
   - **Detection:** Git will notify

---

## Success Criteria

### Functional Requirements

- ✅ Build succeeds on fresh machine without sops key
- ✅ Build succeeds on existing machine with sops key
- ✅ All secrets load correctly when key is present
- ✅ No secrets attempted to load when key is missing
- ✅ Clear warning messages guide users
- ✅ Backward compatible with existing integration

### Non-Functional Requirements

- ✅ Code is well-organized and maintainable
- ✅ Clear separation of concerns (bundles vs features)
- ✅ Documentation is comprehensive and accurate
- ✅ Easy to add new work profiles
- ✅ Consistent with main repo patterns

### Integration Requirements

- ✅ Main repo builds successfully
- ✅ Private modules integrate smoothly
- ✅ No breaking changes to existing configs
- ✅ Multiple import methods available

---

## Timeline Estimate

| Phase | Task | Time | Cumulative |
|-------|------|------|------------|
| 1 | Add flake-parts infrastructure | 1h | 1h |
| 2 | Restructure module directory | 1h | 2h |
| 3 | Implement graceful sops handling | 2h | 4h |
| 4 | Update main repo integration | 1h | 5h |
| 5 | Add future-proof exports | 0.5h | 5.5h |
| - | Testing and validation | 1h | 6.5h |
| - | Documentation | 0.5h | 7h |
| - | Buffer for issues | 1h | 8h |

**Total Estimated Time: 6-8 hours**

---

## Next Steps

1. Review this plan for accuracy and completeness
2. Get approval from user
3. Create backup branch in private repo
4. Execute Phase 1
5. Test and validate
6. Proceed to Phase 2
7. Continue through all phases
8. Final validation
9. Merge to main
10. Update main repo flake.lock

---

## Notes

- This migration is **breaking** in terms of directory structure
- Outputs remain **backward compatible**
- New patterns are **opt-in** (can continue using old import style)
- Graceful degradation is **automatic** (no user intervention needed)
- Future extensions (nixos, darwin, packages) are **ready** (structure in place)

---

**Plan Status:** ✅ Ready for Implementation  
**Last Updated:** 2026-01-22  
**Author:** OpenCode Planning Agent
