# commands

## initial deployment (nixos-anywhere)

### on Linux

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /home/zshen/.config/sops/age \
root@10.1.140.104
```

### on Darwin

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /Users/zshen/.config/sops/age \
root@10.1.140.104
```

## remote switch

### homelab-0

```nix
nixos-rebuild switch --flake .#homelab-0 \
  --target-host root@10.1.140.104
```

### homelab-1

```nix
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@10.1.140.105
```
