# commands

## initial deployment (nixos-anywhere)

### on Linux

#### homelab-0

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /home/zshen/.config/sops/age \
nixos@192.168.50.192
```

#### homelab-1

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-1 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-1.nix \
--extra-files /home/zshen/.config/sops/age \
nixos@192.168.50.184
```

### on Darwin

```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /Users/zshen/.config/sops/age \
nixos@192.168.50.192
```

## remote switch

### homelab-0

```nix
nixos-rebuild switch --flake .#homelab-0 \
  --target-host root@192.168.50.192
```

### homelab-1

```nix
nixos-rebuild switch --flake .#homelab-1 \
  --target-host root@192.168.50.184
```
