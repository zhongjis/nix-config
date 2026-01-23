# zshen's nix-config

This is my personal nix-config. It is always a work in progress as I love tweaking.

## Special Thanks

- https://github.com/vimjoyer/

## System Status

| host                  | home-manager profile              | system         |
| --------------------- | --------------------------------- | -------------- |
| framework-16          | zshen@framework-16                | x86_64-linux   |
| Zhongjies-MacBook-Pro | zshen@Zhongjies-MacBook-Pro.local | aarch64-darwin |

## Get Started

1. install nix (https://zero-to-nix.com/start/install)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
```

2. clone this repo
3. setup keys.txt (for sops-nix)

```nix
age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
```

### Nix-Darwin

```bash
# first time setup
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#mac-m1-max

# switch
nh darwin switch .
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

### NixOS

- switch NixOS

```bash
nh os switch .
```

- test NixOS (TBD)

## Useful cmds

```bash
# useful nix cmds
nix run github:zhongjis/nix-update-input # upgrade specific input
nh search <query> # search nixpkgs
```

## Development Templates

This flake provides reusable development environment templates. Use them to quickly set up project-specific dev shells.

### Available Templates

| Template  | Description                       | Includes                |
| --------- | --------------------------------- | ----------------------- |
| `java8`   | Java 8 development environment    | JDK 8, Maven, Lombok    |
| `nodejs22`| Node.js 22 development environment| Node.js 22, pnpm        |

### Using Templates

**Create a new project from a template:**

```bash
# Create a new directory with the template
nix flake new -t github:zhongjis/nix-config#nodejs22 ./my-project

# Or initialize in current directory
nix flake new -t github:zhongjis/nix-config#java8 .
```

**Enter the development shell:**

```bash
# After creating from template
cd my-project
nix develop

# Or use direnv for automatic activation
echo "use flake" > .envrc
direnv allow
```

**List available templates:**

```bash
nix flake show github:zhongjis/nix-config
```

## Secret Management

I use [sops-nix](https://github.com/Mic92/sops-nix)'s home-manager module.

```bash
nix run nixpkgs#sops -- secrets.yaml # view secrets
```

more about sops see https://github.com/getsops/sops#2usage

# TODOs

NOTE: most of the changes (like for neovim) are changed on the way while im using it. this list just for later in case I have nothing to do.

see [here](https://github.com/users/zhongjis/projects/5)

## Notes

### Build directly from repo

adding inputs

```nix
inputs = {
    trouble-nvim = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
}
```

override in overlays

```nix
  modifications = final: prev: rec {
    vimPlugins =
      prev.vimPlugins
      // {
        trouble-nvim =
          prev.vimUtils.buildVimPlugin
          {
            name = "trouble.nvim";
            src = inputs.trouble-nvim;
          };
      };
  };
```
