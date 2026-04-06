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

type MessageContentPart = {
  type?: string;
  text?: string;
};

type MessageLike = {
  role?: string;
  content?: string | MessageContentPart[];
  timestamp?: number;
};

type ContextEventLike = {
  messages: MessageLike[];
};

type ContextEventResultLike = {
  messages?: MessageLike[];
};

type ToolCallEventLike = {
  toolName?: unknown;
  input?: Record<string, unknown> | null;
};

type ToolCallResultLike = {
  block?: boolean;
  reason?: string;
};

type ExtensionContextLike = {
  ui?: {
    notify: (message: string, level?: string) => void;
  };
};

type SessionHandler = (_event: unknown, _ctx: ExtensionContextLike) => void | Promise<void>;
type ContextHandler = (
  event: ContextEventLike,
  ctx: ExtensionContextLike,
 ) => ContextEventResultLike | void | Promise<ContextEventResultLike | void>;
type ToolCallHandler = (
  event: ToolCallEventLike,
  ctx: ExtensionContextLike,
 ) => ToolCallResultLike | void | Promise<ToolCallResultLike | void>;

type ExtensionApiLike = {
  on: {
    (event: "input", handler: InputHandler): void;
    (event: "session_start", handler: SessionHandler): void;
    (event: "context", handler: ContextHandler): void;
    (event: "tool_call", handler: ToolCallHandler): void;
  };
};

const PLAN_PATTERN = /^\/plan(?:\s+([\s\S]+))?$/;
const PLAN_MODE_MARKER = "Plan mode active.";
const PLAN_MODE_PROMPT_MARKER = "<prometheus-plan-mode>";
const REVIEW_DEPTH_QUESTION_ID = "plan-review-depth";

const PROMETHEUS_PLAN_MODE_PROMPT = `${PLAN_MODE_PROMPT_MARKER}
You are the active planner for OMP built-in /plan mode. Behave like Prometheus from Oh My OpenAgent, adapted to OMP tools and OMP plan mode.

Core behavior:
- You are a planner, not an implementer. Stay read-only except for local://PLAN.md and local://prometheus-draft.md.
- Work in phases: interview -> Metis gap review -> plan draft -> self-review -> Momus review -> optional high-accuracy review -> exit_plan_mode.
- Use OMP-native tool payloads only.
- After approval, execution runs in a fresh standard OMP agent session, not Atlas or any other specialized plan runner.
- Write the plan for one capable OMP implementation agent using normal OMP tools. Do not depend on planner-only jargon, checkbox bookkeeping, or OMO-specific orchestration roles during execution.

Mandatory lifecycle:
1. Register the planning lifecycle with todo_write using an ops array so the plan steps stay visible.
2. Classify the request, restate the goal, and gather repo evidence before locking the design.
3. Before drafting or finalizing any non-trivial plan, call the OMP task tool with agent "metis" at least once. Use Metis to catch missing constraints, guardrails, scope creep, assumptions, and acceptance gaps.
4. Draft local://PLAN.md as plain, self-contained markdown for a fresh OMP implementation session. Prefer this structure:
- # Title
- ## Goal
- ## Constraints and Assumptions
- ## Key Findings
- ## Relevant Files
- ## Implementation Sequence
- ## Verification
- ## Risks and Notes
- You may add narrow sections when they improve execution, but do not force OMO-specific structure such as ## TODOs, Atlas-oriented handoff blocks, or checkbox task lists.
5. Self-review the draft. Classify remaining gaps as critical, minor, or ambiguous, and fix everything you can before external review.
6. Before approval, call the OMP task tool with agent "momus" and pass the current local://PLAN.md body inline in the task context or assignment, together with the target path label. Do not rely on Momus being able to read the parent session's local:// files directly. If Momus rejects, fix every blocker and resubmit until Momus returns OKAY.
7. If the user did not already specify review depth, present the post-plan choice with the OMP ask tool using one question with id "plan-review-depth" and two options:
- Approve current reviewed plan
- Run high accuracy review
8. If the user chooses high accuracy review, harden the plan further, then run another Momus review loop until the strengthened draft returns OKAY.
9. Only call exit_plan_mode after Metis participated and Momus approved the current plan.

Planning standards:
- Name real files, concrete sequence, dependencies, verification commands, scope boundaries, and failure modes.
- Prefer existing repo patterns over invention.
- Use ask only for material ambiguities that tools cannot answer.
- Never present a plan as final before Metis and Momus have both participated.

Tool shapes:
- ask => {"questions":[...]}
- task => {"agent":"...","context":"...","tasks":[...]}
- todo_write => {"ops":[...]}
- exit_plan_mode => {"title":"FEATURE_PLAN"}
</prometheus-plan-mode>`;

function extractTextContent(message: MessageLike | undefined): string {
  if (!message) {
    return "";
  }

  const { content } = message;
  if (typeof content === "string") {
    return content;
  }

  if (!Array.isArray(content)) {
    return "";
  }

  return content
    .filter((part): part is MessageContentPart => typeof part === "object" && part !== null)
    .filter(part => part.type === "text" && typeof part.text === "string")
    .map(part => part.text ?? "")
    .join("\n");
}

function isPlanModeContextMessage(message: MessageLike | undefined): boolean {
  return extractTextContent(message).includes(PLAN_MODE_MARKER);
}

function isInjectedPlanPrompt(message: MessageLike | undefined): boolean {
  return message?.role === "developer" && extractTextContent(message) === PROMETHEUS_PLAN_MODE_PROMPT;
}

function buildMessageKey(message: MessageLike, index: number, text: string): string {
  const timestampPart = Number.isFinite(message.timestamp) ? String(message.timestamp) : `index:${index}`;
  return `${timestampPart}:${text}`;
}

function isReviewDepthQuestion(input: Record<string, unknown> | null | undefined): boolean {
  const questions = input?.questions;
  if (!Array.isArray(questions)) {
    return false;
  }

  return questions.some(question => {
    if (typeof question !== "object" || question === null) {
      return false;
    }

    const id = (question as { id?: unknown }).id;
    return id === REVIEW_DEPTH_QUESTION_ID;
  });
}

function getToolPath(input: Record<string, unknown> | null | undefined): string | null {
  const path = input?.path;
  return typeof path === "string" ? path : null;
}

function isPlanModePrompt(text: string): boolean {
  return PLAN_PATTERN.test(text.trim());
}

export default function planExtension(pi: ExtensionApiLike): void {
  const injectedMessageKeys = new Set<string>();
  let planModeActive = false;
  let metisConsulted = false;
  let momusReviewCount = 0;
  let reviewDepthAsked = false;
  let highAccuracyRequested = false;

  pi.on("session_start", async (_event, _ctx) => {
    injectedMessageKeys.clear();
    planModeActive = false;
    metisConsulted = false;
    momusReviewCount = 0;
    reviewDepthAsked = false;
    highAccuracyRequested = false;
  });

  pi.on("input", event => {
    if (!isPlanModePrompt(event.text)) {
      return;
    }

    return { text: event.text.trim() };
  });

  pi.on("context", async (event, ctx) => {
    const hasPlanModeContext = event.messages.some(message => isPlanModeContextMessage(message));
    if (!hasPlanModeContext) {
      planModeActive = false;
      metisConsulted = false;
      momusReviewCount = 0;
      reviewDepthAsked = false;
      highAccuracyRequested = false;
      return;
    }

    if (!planModeActive) {
      planModeActive = true;
      metisConsulted = false;
      momusReviewCount = 0;
      reviewDepthAsked = false;
      highAccuracyRequested = false;
      injectedMessageKeys.clear();
      ctx.ui?.notify("Prometheus Plan Lifecycle Active", "info");
    }

    const lastUserIndex = [...event.messages].findLastIndex(message => message.role === "user");
    if (lastUserIndex < 0) {
      return;
    }

    const lastUserMessage = event.messages[lastUserIndex];
    const lastUserText = extractTextContent(lastUserMessage).trim();
    if (lastUserText.length === 0) {
      return;
    }

    highAccuracyRequested = event.messages
      .filter(message => message.role === "user")
      .map(message => extractTextContent(message))
      .join("\n")
      .toLowerCase()
      .includes("high accuracy");

    if (isInjectedPlanPrompt(event.messages[lastUserIndex - 1])) {
      return;
    }

    const messageKey = buildMessageKey(lastUserMessage, lastUserIndex, lastUserText);
    if (injectedMessageKeys.has(messageKey)) {
      return;
    }

    injectedMessageKeys.add(messageKey);

    return {
      messages: [
        ...event.messages.slice(0, lastUserIndex),
        {
          role: "developer",
          content: PROMETHEUS_PLAN_MODE_PROMPT,
          timestamp: lastUserMessage.timestamp,
        },
        ...event.messages.slice(lastUserIndex),
      ],
    };
  });

  pi.on("tool_call", async (event, _ctx) => {
    if (!planModeActive || typeof event.toolName !== "string") {
      return;
    }

    if (event.toolName === "task") {
      const agent = event.input?.agent;
      if (agent === "metis") {
        metisConsulted = true;
      }
      if (agent === "momus") {
        momusReviewCount += 1;
      }
      return;
    }

    if ((event.toolName === "write" || event.toolName === "edit") && getToolPath(event.input) === "local://PLAN.md" && !metisConsulted) {
      return {
        block: true,
        reason: "Prometheus plan lifecycle incomplete. Consult Metis before drafting or updating local://PLAN.md.",
      };
    }

    if (event.toolName === "ask" && isReviewDepthQuestion(event.input)) {
      reviewDepthAsked = true;
      return;
    }

    if (event.toolName !== "exit_plan_mode") {
      return;
    }

    const missingSteps = [
      !metisConsulted ? "Metis consultation via the OMP task tool with agent \"metis\"" : null,
      momusReviewCount < 1 ? "Momus review via the OMP task tool with agent \"momus\"" : null,
      highAccuracyRequested && momusReviewCount < 2
        ? "a second Momus review pass for high accuracy mode"
        : null,
      !highAccuracyRequested && !reviewDepthAsked
        ? "the post-plan review-depth question via ask id \"plan-review-depth\""
        : null,
    ].filter((step): step is string => step !== null);

    if (missingSteps.length === 0) {
      return;
    }

    return {
      block: true,
      reason: `Prometheus plan lifecycle incomplete. Before exiting plan mode, complete: ${missingSteps.join(", ")}.`,
    };
  });
}