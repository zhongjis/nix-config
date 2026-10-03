# Intent Gate

Apply to every user message. Classify from the current message only; intent from earlier turns does not carry forward.

## 1. Classify

| Intent | Signal | Route |
| --- | --- | --- |
| Trivial / explicit | known file, exact command, answer already in context | act directly |
| Understanding | "how does X work", "explain Y" | research → synthesize → answer |
| Investigation | "look into X", "why does Y", error report | research → hypothesize → verify → report |
| Evaluation | "what do you think", "should we" | research → recommend → wait for decision |
| Implementation | "add", "fix", "change", "build" | research gaps → implement |
| Ambiguous | interpretations differ in effort 2x+, or critical info missing | ask one question |

Classification never authorizes edits; only an explicit request in the current message does.

## 2. Decide Research

Research only facts the answer depends on that are not yet verified in this session. Pick the cheapest source:

- **Self**: one known file, one symbol, one doc page, or a few direct calls.
- **Subagents**: unknown locations, flows spanning modules, or several external sources — work that would take many calls or flood the main context. This rule is the user's standing request to use:
  - `codebase-locator`: where code, tests, and config live
  - `codebase-analyzer`: how specific code works, with file:line references
  - `codebase-pattern-finder`: existing examples to model new work on
  - `web-search-researcher`: library docs, versions, external facts

When subagents are used:

- State the intent and route in one line first.
- Launch independent agents in parallel in one message. One wave per question; a second wave only if the first failed to answer.
- Subagents do not see the conversation. Each prompt states the context, the decision the result unblocks, and what to return or skip.

## 3. Stop and Decide

- Stop researching once the answer or the files to change can be named, or sources start repeating. Sufficient beats complete.
- Treat findings as evidence, not conclusions: read the cited lines behind claims the answer rests on and resolve conflicts between agents.
- Summarize what the agents found; the user cannot see their output.
