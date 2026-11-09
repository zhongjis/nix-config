// Adapted from ChmaraX/herdr-nvim (MIT; LICENSE-herdr-nvim).
// No Rust wrapper: the controller starts a real nvim and edits it over its socket.
import { exec, focused, hc, home, panes, spaces } from "herdr";

// Capture before awaiting: the person may switch tabs meanwhile.
export function place(f = focused()) {
  if (!f?.space || !f?.tab) return null;
  const terminal = f.terminal ?? null;
  return { space: f.space, tab: f.tab, terminal, cwd: terminal ? f.cwd ?? null : null };
}

export function socket(tab) {
  return `${home()}/.cache/herdr-filetree/nvim-${tab}.sock`;
}

export async function startNvim(at, file = null) {
  const folder = at.cwd || panes().find((p) => p.tab === at.tab && p.cwd)?.cwd || spaces().find((s) => s.id === at.space)?.folder || home();
  const repo = await exec("git", ["-C", folder, "rev-parse", "--show-toplevel"]);
  const cwd = repo.code === 0 ? repo.stdout.trim() : folder;
  const sock = socket(at.tab);
  const mkdir = await exec("mkdir", ["-p", `${home()}/.cache/herdr-filetree`]);
  if (mkdir.code !== 0) throw new Error(mkdir.stderr);
  const rm = await exec("rm", ["-f", sock]);
  if (rm.code !== 0) throw new Error(rm.stderr);
  const result = await hc(["run", "--json", "--bg", "--no-parent", "--cwd", cwd, "--label", `filetree.nvim=${at.tab}`, "--", "nvim", "--listen", sock, ...(file ? ["--", file] : [])]);
  if (result.code !== 0) throw new Error(result.stderr || result.stdout);
  return JSON.parse(result.stdout).address;
}

export async function editNvim(tab, file) {
  // JSON keeps control characters out of the Ex command; nvim handles
  // filename escaping. Encode '<' for --remote-send's key notation too.
  const literal = "'" + JSON.stringify(file).replaceAll("'", "''").replaceAll("<", "<LT>") + "'";
  const keys = `<C-\\><C-n>:execute 'edit ' . fnameescape(json_decode(${literal}))<CR>`;
  const result = await exec("nvim", ["--server", socket(tab), "--remote-send", keys]);
  if (result.code !== 0) throw new Error(result.stderr || result.stdout);
}
