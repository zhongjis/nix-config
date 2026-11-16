# Agent Environment

- Global instructions, harness settings: `~/personal/nix-config`
- Skills: `~/personal/agent-skills`
- Pi modes, agents, extensions: `~/personal/pi-config`
- Session logs, to observe, audit or retro another agent's run (read via the `*-session-logs` skill): `~/.claude/projects/<cwd-slug>/`, `~/.pi/agent/sessions/<cwd-slug>/`
- Signed-in pages: the user signs in with Helium (`~/.config/net.imput.helium`), not Chrome. For a read-only check, copy `Local State` and `Default/{Cookies,Preferences,Local Storage}` to a scratchpad, launch `helium --headless=new --user-data-dir=<copy> --remote-debugging-port=9351 --password-store=gnome-libsecret`, attach with `agent-browser --cdp 9351`, and delete the copy when done.
