import { existsSync } from "node:fs";
import { execFileSync, spawn } from "node:child_process";

const REWRITE_TIMEOUT_MS = 5_000;

type BashExecOptions = {
  onData?: (chunk: Buffer) => void;
  signal?: AbortSignal;
  timeout?: number;
  env?: NodeJS.ProcessEnv;
};

type BashOperations = {
  exec: (
    command: string,
    cwd: string,
    options: BashExecOptions,
  ) => Promise<{ exitCode: number | null }>;
};

type ExtensionApi = {
  on: (eventName: "tool_call" | "user_bash", handler: (event: unknown) => unknown) => void;
};

type ToolCallEvent = {
  toolName?: unknown;
  input?: {
    command?: unknown;
  };
};

type UserBashEvent = {
  command?: unknown;
  excludeFromContext?: boolean;
};

// UPSTREAM-PATCH: skip rtk rewrite for rg/grep commands using flags that
// collide with `rtk grep`'s own short options or break its clap parser.
// Tracking upstream:
//   - rtk-ai/rtk#1604  (hook rewrite produces unparseable args; -l, -E, -q, -A/-B/-C)
//   - rtk-ai/rtk#1436  (rtk grep is not grep-compatible)
//   - rtk-ai/rtk#236   (find/grep rewrite breaks on native flags)
//   - rtk-ai/rtk#1367  (rg rewrite edge case on quoted regex)
//   - rtk-ai/rtk#1219  (open PR: accept -r/--recursive)
// Remove this function and its call sites once those are resolved.
function shouldSkipRtkRewrite(command: string): boolean {
  const trimmed = command.trimStart();
  // Only touch bare `rg ...` / `grep ...` invocations. Anything pipelined,
  // command-substituted, or compound falls through to normal rewrite.
  const match = /^(?:rg|grep)\s+(.*)$/s.exec(trimmed);
  if (!match) {
    return false;
  }
  const rest = match[1];
  // Semantic collisions with `rtk grep`'s own short flags:
  //   -l  rtk: --max-len       vs rg/grep: --files-with-matches
  //   -m  rtk: --max           vs rg/grep: --max-count
  //   -c  rtk: --context-only  vs rg/grep: --count
  //   -v  rtk: --verbose       vs rg/grep: --invert-match
  // Clap parse failures observed in #1604 / #229 / #236:
  //   -E  extended regex, -q quiet, -A/-B/-C N context
  // Flag tokens only — avoid matching inside patterns or quoted strings by
  // requiring preceding whitespace or start-of-string.
  const conflictFlag = /(^|\s)-(?:[lmcvEq]|[ABC]\b|[ABC]\s*\d+)(?=\s|=|$)/;
  // Short-flag clusters like -rn, -nE, -nl that embed a conflicting letter.
  const conflictCluster = /(^|\s)-[a-zA-Z]*[lmcvEq][a-zA-Z]*(?=\s|$)/;
  return conflictFlag.test(rest) || conflictCluster.test(rest);
}

function rtkRewriteCommand(command: string): string | undefined {
  if (shouldSkipRtkRewrite(command)) {
    return undefined;
  }
  try {
    return execFileSync("rtk", ["rewrite", command], {
      encoding: "utf-8",
      timeout: REWRITE_TIMEOUT_MS,
    }).trimEnd();
  } catch {
    return undefined;
  }
}

function getShellCommand(command: string): [string, string[]] {
  const shell = process.env.SHELL || "/bin/bash";
  return [shell, ["-lc", command]];
}

function createLocalRewriteOperations(): BashOperations {
  return {
    exec: (command, cwd, options) =>
      new Promise<{ exitCode: number | null }>((resolve, reject) => {
        if (!existsSync(cwd)) {
          reject(new Error(`Working directory does not exist: ${cwd}`));
          return;
        }

        const rewrittenCommand = rtkRewriteCommand(command) ?? command;
        const [shell, args] = getShellCommand(rewrittenCommand);
        const child = spawn(shell, args, {
          cwd,
          detached: true,
          env: options.env ?? process.env,
          stdio: ["ignore", "pipe", "pipe"],
        });

        let timedOut = false;
        let timeoutHandle: NodeJS.Timeout | undefined;

        if (options.timeout !== undefined && options.timeout > 0) {
          timeoutHandle = setTimeout(() => {
            timedOut = true;
            if (child.pid) {
              try {
                process.kill(-child.pid, "SIGKILL");
              } catch {
                child.kill("SIGKILL");
              }
            }
          }, options.timeout * 1000);
        }

        const onData = options.onData ?? (() => {});
        child.stdout?.on("data", onData);
        child.stderr?.on("data", onData);

        const onAbort = () => {
          if (child.pid) {
            try {
              process.kill(-child.pid, "SIGKILL");
            } catch {
              child.kill("SIGKILL");
            }
          }
        };

        if (options.signal) {
          if (options.signal.aborted) {
            onAbort();
          } else {
            options.signal.addEventListener("abort", onAbort, { once: true });
          }
        }

        child.on("error", (error) => {
          if (timeoutHandle) {
            clearTimeout(timeoutHandle);
          }
          if (options.signal) {
            options.signal.removeEventListener("abort", onAbort);
          }
          reject(error);
        });

        child.on("close", (code) => {
          if (timeoutHandle) {
            clearTimeout(timeoutHandle);
          }
          if (options.signal) {
            options.signal.removeEventListener("abort", onAbort);
          }

          if (options.signal?.aborted) {
            reject(new Error("aborted"));
          } else if (timedOut) {
            reject(new Error(`timeout:${options.timeout}`));
          } else {
            resolve({ exitCode: code });
          }
        });
      }),
  };
}

export default function rtkExtension(pi: ExtensionApi): void {
  pi.on("tool_call", (event) => {
    const toolCall = event as ToolCallEvent;
    if (toolCall.toolName !== "bash") {
      return;
    }

    const command = toolCall.input?.command;
    if (typeof command !== "string") {
      return;
    }

    const rewrittenCommand = rtkRewriteCommand(command);
    if (rewrittenCommand) {
      toolCall.input!.command = rewrittenCommand;
    }
  });

  pi.on("user_bash", (event) => {
    const userBash = event as UserBashEvent;
    if (userBash.excludeFromContext) {
      return;
    }

    if (typeof userBash.command !== "string") {
      return;
    }

    // Only override Pi's built-in !cmd execution path when RTK is currently usable.
    if (!rtkRewriteCommand(userBash.command)) {
      return;
    }

    return {
      operations: createLocalRewriteOperations(),
    };
  });
}
