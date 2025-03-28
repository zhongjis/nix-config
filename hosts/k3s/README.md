```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--copy-host-keys \
root@10.1.140.101
```
