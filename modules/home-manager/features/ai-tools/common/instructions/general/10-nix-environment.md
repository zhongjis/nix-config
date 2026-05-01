# Nix Environment Awareness

**Context:** This environment uses the Nix package manager. Prefer ephemeral or project-scoped execution over mutating the host.

## Command Selection

1. **Project environment first**
   - If the repo has `flake.nix`, prefer `nix develop` for project work.
   - If the project already defines its own package manager or dev environment, use that instead of inventing a parallel setup.

2. **Choose the narrowest Nix command**
   - Use `nix develop` for project environments and repo-scoped work.
   - Use `nix shell` for ad-hoc tools, arbitrary commands, and multiple packages.
   - Use `nix run` for a single package's default executable.

3. **Avoid global mutable installs**
   - `apt` / `yum` installs on NixOS
   - `brew install` as the default answer on nix-darwin or mixed Nix systems
   - `pip install --global` / `pip install --user`
   - `npm install -g`
   - `sudo make install`

4. **Do not mutate the host environment unless the user explicitly asks for a persistent setup change**
   - Prefer ephemeral commands and project-scoped workflows over system-wide changes.

## Detailed Ad-hoc Guidance

For detailed Python, Node.js, and ad-hoc command selection, use the `nix-ad-hoc-execution` skill.
