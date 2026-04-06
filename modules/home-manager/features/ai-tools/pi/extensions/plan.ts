type InputEventLike = {
  text: string;
};

type InputEventResultLike = {
  handled?: boolean;
  text?: string;
};

type InputHandler = (
  event: InputEventLike,
 ) => InputEventResultLike | void | Promise<InputEventResultLike | void>;

type ExtensionApiLike = {
  on: {
    (event: "input", handler: InputHandler): void;
  };
};

const PLAN_PATTERN = /^\/plan(?:\s+([\s\S]+))?$/;
const DELEGATION_MARKER = 'Use the OMP task tool with {"agent":"prometheus"';

const PROMETHEUS_SESSION_PROMPT = `You are in Prometheus plan mode. Use the OMP task tool with {"agent":"prometheus","tasks":[...]} to create a concrete, reviewed plan. When the user describes their goal, pass the full context to Prometheus.

Tool shape reminders:
- task uses {"agent":"prometheus","context":"...","tasks":[...]}
- if clarification is truly required, ask uses a `questions` array payload
- exit_plan_mode requires {"title":"FEATURE_PLAN"}

Prometheus will:
- Use local://prometheus-draft.md as scratch space when helpful
- Converge on the authoritative plan at local://PLAN.md
- Use ask only for real ambiguities it cannot resolve by exploration
- Call exit_plan_mode when the plan is ready

Drive the Prometheus lifecycle end to end.`;

const PROMETHEUS_DELEGATION_PROMPT = `Use the OMP task tool with {"agent":"prometheus","tasks":[...]} to create a concrete plan for the following request.

User request:

$USER_REQUEST

Pass the user goal above to Prometheus. Include the active scope, constraints, non-goals,
and any critical file paths already known.

Tool shape reminders:
- task uses {"agent":"prometheus","context":"...","tasks":[...]}
- if clarification is truly required, ask uses a `questions` array payload
- todo_write uses {"ops":[...]}
- exit_plan_mode requires {"title":"FEATURE_PLAN"}

Prometheus will:
- Use local://prometheus-draft.md as scratch space when helpful
- Converge on the authoritative plan at local://PLAN.md
- Use ask only for real ambiguities it cannot resolve by exploration
- Use todo_write for its planning workflow when useful
- Call exit_plan_mode when the plan is ready

Prometheus may delegate focused planning or discovery work with the OMP task tool by setting the target `agent` field appropriately.

Do not ask the user to manually run planning tools or manually exit plan mode.
Drive the Prometheus lifecycle end to end.`;

function buildDelegationPrompt(userRequest: string): string {
  return PROMETHEUS_DELEGATION_PROMPT.replace("$USER_REQUEST", userRequest);
}

export default function planExtension(pi: ExtensionApiLike): void {
  pi.on("input", event => {
    const match = event.text.trim().match(PLAN_PATTERN);
    if (!match || event.text.includes(DELEGATION_MARKER)) {
      return;
    }

    const userRequest = match[1]?.trim();
    if (!userRequest) {
      return { text: `/plan ${PROMETHEUS_SESSION_PROMPT}` };
    }

    return { text: `/plan ${buildDelegationPrompt(userRequest)}` };
  });
}
