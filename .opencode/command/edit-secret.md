---
command: /edit-secret
description: Edit SOPS-encrypted secrets
syntax: |
  /edit-secret <file> [options]
options:
  - --view: View decrypted secret without editing
  - --validate: Validate YAML syntax
  - --switch: Switch system after editing
examples:
  - "/edit-secret ssh.yaml"
  - "/edit-secret ssh.yaml --view"
  - "/edit-secret ssh.yaml --validate --switch"
---

# Edit Secret Command

Edits SOPS-encrypted secret files securely.

## Usage

```bash
/edit-secret <file>              # Edit secret
/edit-secret <file> --view       # View decrypted
/edit-secret <file> --validate   # Validate YAML
/edit-secret <file> --switch     # Deploy after edit
```

## Available Secret Files

| File | Purpose |
|------|---------|
| `ssh.yaml` | SSH keys |
| `ai-tokens.yaml` | AI API tokens |
| `access-tokens.yaml` | Access tokens |
| `homelab.yaml` | Homelab secrets |

## Examples

### Edit Secret

```bash
$ /edit-secret ssh.yaml

=== Editing ssh.yaml ===

1. Decrypting...
✅ Decrypted

2. Opening editor (vim)...

[Editor opens with decrypted content]
secrets:
    github-key: "ssh-ed25519 ..."
    gitlab-key: "ssh-ed25519 ..."

3. Save and close editor...

4. Encrypting...
✅ Encrypted

5. Validating...
✅ YAML valid
✅ Encryption valid

File saved: secrets/ssh.yaml

Run /switch-host to deploy changes.
```

### View Secret

```bash
$ /edit-secret ssh.yaml --view

=== ssh.yaml (decrypted) ===

secrets:
    github-key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5L..."
    gitlab-key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5L..."

[End of file]
```

### Validate

```bash
$ /edit-secret ssh.yaml --validate

=== Validating ssh.yaml ===

1. YAML syntax...
✅ Valid YAML

2. SOPS encryption...
✅ Encrypted with age key

3. All secrets present...
✅ 2 secrets found

4. Format check...
✅ SOPS format valid

Validation passed.
```

### Edit and Deploy

```bash
$ /edit-secret ai-tokens.yaml --switch

=== Editing ai-tokens.yaml ===

1. Decrypting... ✅
2. Opening editor...

[Edit OpenAI key]

3. Encrypting... ✅

=== Deploying to framework-16 ===

1. Validating...
✅ Syntax OK

2. Switching...
✅ Deployed to /run/secrets/

3. Verifying...
✅ ai-token available at /run/secrets/ai-token

Changes deployed successfully.
```

## Secret Structure

```yaml
# secrets/example.yaml
secrets:
    # Simple key-value
    api-key: ENC[AES256_GCM,data:...,tag:...,type:str]
    
    # Complex data
    credentials:
        username: ENC[...]
        password: ENC[...]
    
    # Array
    keys:
        - ENC[...]
        - ENC[...]
```

## Best Practices

1. **Validate before deploying** - Always use `--validate`
2. **Deploy after editing** - Use `--switch`
3. **Never commit decrypted** - Only encrypted files in git
4. **Use meaningful names** - Clear secret purpose
5. **Rotate regularly** - Periodic secret rotation
