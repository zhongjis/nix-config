# Secret Management Workflow

Workflow for managing SOPS-encrypted secrets in the nix-config repository.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                 Secret Management Workflow                   │
├─────────────────────────────────────────────────────────────┤
│  1. Create Secret File                                       │
│     → Initialize new encrypted YAML file                     │
│  2. Add Secret Content                                       │
│     → Edit and encrypt sensitive data                        │
│  3. Configure Access                                         │
│     → Add to sops.secrets in host config                     │
│  4. Deploy                                                   │
│     → Switch system to deploy secrets                        │
│  5. Use Secrets                                              │
│     → Access at runtime via /run/secrets or config           │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Create Secret File

### Initialize New Secret

```bash
# Create empty encrypted file
nix run nixpkgs#sops -- secrets/new-service.yaml
```

### Structure

```yaml
# secrets/new-service.yaml
secrets:
    api_key: ""
    database_password: ""
    api_token: ""
```

### Configure SOPS

```yaml
# .sops.yaml
keys:
  - &zshen age1zshen...  # zshen's age key
  
creation_rules:
  - filename_regex: secrets.*\.yaml$
    key_groups:
      - age:
          - *zshen
```

## Step 2: Add Secret Content

### Edit Secrets

```bash
# Open editor (decrypted view)
/edit-secret new-service.yaml

# With specific editor
EDITOR=vim nix run nixpkgs#sops -- secrets/new-service.yaml
```

### Add Content

```yaml
secrets:
    api_key: ENC[AES256_GCM,data:abc123...,tag:def456...,type:str]
    database_password: ENC[AES256_GCM,data:ghi789...,type:str]
    
    complex_secret:
        username: ENC[...]

# Arrays
ssh_keys:
    - ENC[...]
    - ENC[...]
```

### Validate

```bash
# Validate YAML syntax
nix run nixpkgs#sops -- --validate secrets/new-service.yaml

# Decrypt and view
nix run nixpkgs#sops -d secrets/new-service.yaml
```

## Step 3: Configure Access

### NixOS Configuration

```nix
# hosts/framework-16/configuration.nix
{ config, ... }: {
  sops.defaultSopsFile = ../secrets/common.yaml;
  sops.secretsFiles = [
    ../secrets/common.yaml
    ../secrets/new-service.yaml
  ];
  
  sops.secrets = {
    # From common.yaml
    api-token = {};
    
    # From new-service.yaml
    api-key = {};
    database-password = {};
  };
}
```

### Home Manager Configuration

```nix
# hosts/framework-16/home.nix
{ config, ... }: {
  sops.defaultSopsFile = ../secrets/common.yaml;
  sops.secretsFiles = [
    ../secrets/common.yaml
    ../secrets/new-service.yaml
  ];
  
  sops.secrets = {
    api-key = {};
    database-password = {};
  };
}
```

### Access Methods

```nix
# As environment variable
environment.sessionVariables = {
  API_KEY = "@api-key";
};

# As file
systemd.services.my-service.serviceConfig = {
  SecretFile = "@database-password";
};

# Direct path access
home.file.".env" = {
  source = config.sops.secrets."api-key".path;
};
```

## Step 4: Deploy

### Deploy to NixOS

```bash
# Switch with secret deployment
nh os switch .

# Verify secrets deployed
ls /run/secrets/
```

### Deploy to Darwin

```bash
# Switch with secret deployment
nh darwin switch .

# Verify secrets deployed
ls ~/.config/sops-nix/secrets/
```

### Deploy Home Manager Only

```bash
# Deploy secrets only
home-manager switch --flake .#zshen@framework-16
```

## Step 5: Use Secrets

### Runtime Locations

| System | Location |
|--------|----------|
| **NixOS** | `/run/secrets/<name>` |
| **Home Manager** | `~/.config/sops-nix/secrets/<name>` |
| **Environment** | `$API_KEY` (if configured) |

### Example Service

```nix
# modules/nixos/features/my-service.nix
{ config, lib, ... }:

let
  cfg = config.myNixOS.features.my-service;
in

{
  options = myNixOS.features.my-service = {
    enable = lib.mkEnableOption "my service";
  };
  
  config = lib.mkIf cfg.enable {
    services.my-service = {
      enable = true;
      
      environment = {
        API_KEY = "@api-key";
        DB_PASSWORD = "@database-password";
      };
      
      serviceConfig = {
        SecretFile = "@database-password";
      };
    };
  };
}
```

## Secret File Organization

```
secrets/
├── access-tokens.yaml        # Access tokens
├── ai-tokens.yaml            # AI API tokens
├── homelab.yaml              # Homelab secrets
├── ssh.yaml                  # SSH keys
├── .claude/                  # Claude settings
│   └── settings.local.json
└── README.md                 # Documentation
```

## Common Operations

### View Decrypted Secret

```bash
/edit-secret ssh.yaml --view

# Or directly
nix run nixpkgs#sops -d secrets/ssh.yaml
```

### Edit Secret

```bash
/edit-secret ssh.yaml

# With validation
/edit-secret ssh.yaml --validate --switch
```

### Rotate Secret

```bash
# Edit to change value
/edit-secret ssh.yaml

# SOPS auto-rotates on save
```

### Delete Secret

```bash
# Remove from YAML file
/edit-secret ssh.yaml
# Delete the secret line

# Remove from configuration
# Edit host config, remove sops.secrets entry
```

## Troubleshooting

### Secret Not Found

```bash
# Check secretsFiles configuration
nix-instantiate --eval -E '
  let
    host = (import ./hosts/framework-16/configuration.nix {
      pkgs = import <nixpkgs> {};
      lib = (import <nixpkgs> {}).lib;
      config = { sops.secretsFiles = []; };
    });
  in
    builtins.attrNames host.config.sops.secretsFiles
'
```

### Permission Denied

```bash
# Check key file permissions
ls -la ~/.config/sops/age/keys.txt

# Fix if needed
chmod 600 ~/.config/sops/age/keys.txt
```

### Decryption Fails

```bash
# Verify key exists
cat ~/.config/sops/age/keys.txt

# Check .sops.yaml has correct key
nix run nixpkgs#sops -- -d secrets.yaml 2>&1 | head -20
```

## Best Practices

1. **Never commit decrypted secrets** - Only encrypted files in git
2. **Use age keys** - More modern than SSH for SOPS
3. **Backup age keys** - Secure location, multiple copies
4. **Use separate files** - Per environment/service
5. **Document secrets** - What each secret is for
6. **Validate before deploy** - Always check syntax
7. **Rotate regularly** - Periodic secret rotation
8. **Use minimal permissions** - Only what's needed
