const ULTRAWORK_PATTERN = /\b(?:ultrawork|ulw)\b/i;
const FENCED_CODE_PATTERN = /(^|\n)[ \t]*(```|~~~)[\s\S]*?\n[ \t]*\2[^\n]*(?=\n|$)/g;
const INLINE_CODE_PATTERN = /`[^`\n]+`/g;

const ULTRAWORK_PROMPT = `<ultrawork-mode>
Maximum rigor for this task. Bias strongly toward Prometheus planning for anything non-trivial. Consult explore/librarian/oracle in parallel when context or docs are missing. Partial completion is failure — do not stop until all work is verified complete.
</ultrawork-mode>`;

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

type ExtensionContextLike = {
  ui?: {
    notify: (message: string, level?: string) => void;
  };
};

type SessionHandler = (_event: unknown, ctx: ExtensionContextLike) => void | Promise<void>;
type ContextHandler = (
  event: ContextEventLike,
  ctx: ExtensionContextLike,
) => ContextEventResultLike | void | Promise<ContextEventResultLike | void>;

type ExtensionApiLike = {
  on: {
    (event: "session_start", handler: SessionHandler): void;
    (event: "context", handler: ContextHandler): void;
  };
};

function stripCode(text: string): string {
  return text.replace(FENCED_CODE_PATTERN, "$1").replace(INLINE_CODE_PATTERN, "");
}

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

function isInjectedUltraworkPrompt(message: MessageLike | undefined): boolean {
  return message?.role === "developer" && extractTextContent(message) === ULTRAWORK_PROMPT;
}

function buildMessageKey(message: MessageLike, index: number, text: string): string {
  const timestampPart = Number.isFinite(message.timestamp) ? String(message.timestamp) : `index:${index}`;
  return `${timestampPart}:${text}`;
}

export default function ultraworkExtension(pi: ExtensionApiLike): void {
  const activatedMessageKeys = new Set<string>();

  pi.on("session_start", async () => {
    activatedMessageKeys.clear();
  });

  pi.on("context", async (event, ctx) => {
    const lastUserIndex = [...event.messages].findLastIndex(message => message.role === "user");
    if (lastUserIndex < 0) {
      return;
    }

    const lastUserMessage = event.messages[lastUserIndex];
    const lastUserText = extractTextContent(lastUserMessage).trim();
    if (lastUserText.length === 0) {
      return;
    }

    const textWithoutCode = stripCode(lastUserText);
    if (!ULTRAWORK_PATTERN.test(textWithoutCode)) {
      return;
    }

    if (isInjectedUltraworkPrompt(event.messages[lastUserIndex - 1])) {
      return;
    }

    const messageKey = buildMessageKey(lastUserMessage, lastUserIndex, lastUserText);
    if (activatedMessageKeys.has(messageKey)) {
      return;
    }

    activatedMessageKeys.add(messageKey);
    ctx.ui?.notify("Ultrawork Mode Activated", "success");

    return {
      messages: [
        ...event.messages.slice(0, lastUserIndex),
        {
          role: "developer",
          content: ULTRAWORK_PROMPT,
          timestamp: lastUserMessage.timestamp,
        },
        ...event.messages.slice(lastUserIndex),
      ],
    };
  });
}
