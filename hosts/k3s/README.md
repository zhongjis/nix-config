```nix
nix run nixpkgs#nixos-anywhere -- \
--flake .#homelab-0 \
--generate-hardware-config nixos-generate-config ./hosts/k3s/hardware-configuration-homelab-0.nix \
--extra-files /home/zshen/.config/sops/age/keys.txt \
root@10.1.140.101
```
