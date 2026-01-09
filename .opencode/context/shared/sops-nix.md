# SOPS-Nix Secret Management

Guide to using SOPS-Nix for managing secrets in the nix-config repository.

## Overview

SOPS-Nix provides atomic secret provisioning using SOPS (Secrets OPerationS) with Age or SSH key encryption.

### Key Features

- **Age/SSH Encryption**: Secrets encrypted with user's keys
- **Atomic Updates**: Changes atomic and safe
- **Runtime Decryption**: Decrypted on boot/run, never stored decrypted
- **Nix Integration**: Seamless integration with NixOS and Home Manager
- **Version Control Safe**: Encrypted files can be committed to git

## Architecture

### Encryption Flow

```
1. Edit encrypted file (secrets.yaml)
   ↓
2. SOPS encrypts with Age/SSH keys
   ↓
3. Commit encrypted file to git
   ↓
4. On system switch, deploy encrypted file
   ↓
5. At runtime, decrypt to /run/secrets (NixOS) or ~/.config/sops-nix (HM)
```

### Secret Locations

| System | Decryption Location |
|--------|---------------------|
| **NixOS** | `/run/secrets/<secret-name>` |
| **Home Manager** | `~/.config/sops-nix/secrets/<secret-name>` |
| **Runtime (NixOS)** | `$XDG_RUNTIME_DIR/secrets.d/<secret-name>` |

## Configuration

### Age Key Setup

1. **Create Age Key**:
   ```bash
   mkdir -p ~/.config/sops/age
   nix run nixpkgs#age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. **Configure in Home Manager**:
   ```nix
   programs.sops = {
     gnupg.sshKeyPaths = [ "$HOME/.ssh/id_ed25519" ];
     ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
   };
   ```

3. **Configure in NixOS**:
   ```nix
   sops = {
     age = {
       keyFile = "/etc/sops/age/keys.txt";
       # or
       keyPaths = ["/etc/sops/age/keys.txt"];
     };
   };
   ```

### SOPS Configuration File

Create `.sops.yaml` in repository root:

```yaml
# .sops.yaml
keys:
  # Age keys
  - &age1 age1qjz...  # Main key
  - &age2 age1abc...  # Backup key
  
  # SSH keys (for existing setups)
  - ssh-ed25519 AAAAC3... user@hostname
  
creation_rules:
  # Encrypt all secrets.yaml files
  - filename_regex: secrets.*\.yaml$
    key_groups:
      - age:
          - *age1
          - *age2
      - ssh:
          - ssh-ed25519 AAAAC3...
    
  # Encrypt specific paths
  - filename_regex: secrets/production/.*
    key_groups:
      - age:
          - *age1
```

### Secret File Structure

```yaml
# secrets.yaml (example)
secrets:
    # Simple key-value
    api_token: ENC[AES256_GCM,data:...,tag:...,type:str]
    database_password: ENC[AES256_GCM,data:...,tag:...,type:str]
    
    # More complex data
    docker_credentials:
        username: ENC[...]
        password: ENC[...]
        server: ENC[...]
    
    # Array
    ssh_keys:
        - ENC[...]
        - ENC[...]
```

## Project Structure

### Secret Files (from project)

```
secrets/
├── access-tokens.yaml     # Access tokens
├── ai-tokens.yaml         # AI API tokens
├── homelab.yaml          # Homelab secrets
├── ssh.yaml              # SSH keys
└── .claude/              # Claude-specific secrets
    └── settings.local.json
```

### .sops.yaml Configuration

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

## Usage

### Creating New Secrets

1. **Create secret file**:
   ```bash
   nix run nixpkgs#sops -- secrets/new-service.yaml
   ```

2. **Add content**:
   ```yaml
   secrets:
       api_key: ""
       database_url: ""
   ```

3. **Edit (opens editor)**:
   ```bash
   nix run nixpkgs#sops -- secrets/new-service.yaml
   ```

4. **Commit**:
   ```bash
   git add secrets/new-service.yaml
   git commit -m "Add secrets for new service"
   ```

### Editing Secrets

```bash
# Edit with default editor
nix run nixpkgs#sops -- secrets/ssh.yaml

# Edit with specific editor
EDITOR=vim nix run nixpkgs#sops -- secrets/ssh.yaml

# View decrypted (without editing)
/edit-secret ssh.yaml --view
```

### Deploying Secrets

Secrets are automatically deployed on system switch:

```bash
# NixOS
nh os switch .

# nix-darwin
nh darwin switch .

# Home Manager
home-manager switch --flake .
```

### Accessing Secrets

#### In NixOS Configuration

```nix
{ config, ... }: {
  sops.secrets = {
    api-token = {};
    ssh-key = {
      path = "/etc/secrets/ssh-key";
      mode = "0600";
      owner = "root";
    };
  };
  
  # Use as environment variable
  environment.sessionVariables = {
    API_TOKEN = "@api-token";
  };
  
  # Use in service configuration
  services.my-service.environment = {
    API_TOKEN = "@api-token";
  };
  
  # Use as file
  systemd.services.my-service.serviceConfig = {
    SecretFile = "@ssh-key";
  };
}
```

#### In Home Manager

```nix
{ config, ... }: {
  sops.secrets = {
    api-token = {};
    git-credentials = {};
  };
  
  # Available as environment variables
  home.sessionVariables = {
    API_TOKEN = "@api-token";
    GIT_CREDENTIALS = "@git-credentials";
  };
  
  # Copy to specific location
  home.file = {
    ".config/my-service/api-token".source = config.sops.secrets."api-token".path;
  };
}
```

#### At Runtime

Secrets are available at:

```bash
# NixOS
cat /run/secrets/api-token

# Home Manager
cat ~/.config/sops-nix/secrets/api-token
```

## Integration with Nix Config

### NixOS Module

```nix
{ config, pkgs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];
  
  sops = {
    age = {
      keyFile = "/etc/sops/age/keys.txt";
    };
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      api-token = {};
      db-password = {};
    };
  };
}
```

### Home Manager Module

```nix
{ config, pkgs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  
  sops = {
    defaultSopsFile = ../secrets.yaml;
    secrets = {
      api-token = {};
      git-credentials = {};
    };
  };
}
```

### Age Key in Home Manager

```nix
{ config, ... }: {
  age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  
  programs.sops = {
    enable = true;
    gnupg.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  };
}
```

## Multi-Host Secret Management

### Shared Secrets

```yaml
# secrets/common.yaml
secrets:
    api-token: ENC[...]
    shared-db-password: ENC[...]
```

### Host-Specific Secrets

```yaml
# secrets/framework-16.yaml
secrets:
    gpu-token: ENC[...]
```

### Configuration

```nix
# hosts/framework-16/configuration.nix
{ config, ... }: {
  sops.defaultSopsFile = ../secrets/common.yaml;
  sops.secretsFiles = [
    ../secrets/common.yaml
    ../secrets/framework-16.yaml  # Host-specific
  ];
  
  sops.secrets = {
    # From common.yaml
    api-token = {};
    # From framework-16.yaml
    gpu-token = {};
  };
}
```

## Best Practices

1. **Use Age keys** (more modern than SSH for SOPS)
2. **Never commit decrypted secrets**
3. **Use separate secrets files** for different environments
4. **Backup age keys** securely
5. **Use `.gitignore`** for decrypted files if any:
   ```
   # .gitignore
   secrets/*.yaml
   !secrets/*.yaml.template
   ```
6. **Validate secrets** before switching:
   ```bash
   nix run nixpkgs#sops -- --validate secrets.yaml
   ```
7. **Use meaningful filenames** (e.g., `production.yaml`, `staging.yaml`)
8. **Rotate keys periodically**

## Troubleshooting

### "SOPS: error: no key found"

Ensure age key is configured:

```bash
# Check key file exists
cat ~/.config/sops/age/keys.txt | head -1

# Verify key in .sops.yaml
```

### Secrets not decrypted

Check module is enabled:

```nix
# NixOS
sops.enable = true;

# Home Manager
programs.sops.enable = true;
```

### Permission denied

Ensure proper permissions:

```bash
chmod 600 ~/.config/sops/age/keys.txt
```

### Host-specific secrets not loading

Verify `secretsFiles` configuration:

```nix
sops.secretsFiles = [
  ../secrets/default.yaml
  ../secrets/${config.networking.hostName}.yaml
];
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `nix run nixpkgs#sops -- <file>` | Edit secret file |
| `nix run nixpkgs#sops -- --validate <file>` | Validate secret file |
| `nix run nixpkgs#sops -- -d <file>` | Decrypt and print |
| `age-keygen -o ~/.config/sops/age/keys.txt` | Generate age key |

## Resources

- [SOPS-Nix GitHub](https://github.com/Mic92/sops-nix)
- [SOPS Documentation](https://github.com/getsops/sops)
- [Age](https://github.com/FiloSottile/age)
