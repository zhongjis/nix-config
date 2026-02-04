# AI Tools Instruction Management

This document provides guidance on managing instructions for AI tools (Claude Code, OpenCode) within this repository. The instruction abstraction layer ensures that AI agents receive the most relevant and efficient guidelines based on their specific tool and environment.

## Overview

The instruction management system uses a tiered approach to organize and deliver instructions:

1.  **Shared Instructions**: General guidelines applicable to all AI tools.
2.  **Tool-Specific Instructions**: Specialized rules or strategies unique to a specific tool's runtime or capabilities.
3.  **Agent/Persona Definitions**: Specialized behavioral instructions for specific tasks or domains.

## Current Instruction Inventory

| File Path | Category | Purpose | Why it's here |
| :--- | :--- | :--- | :--- |
| `shared/instructions/nix-environment.md` | Shared | Nix environment awareness and ad-hoc package usage. | Applies to any AI tool running in this Nix-managed configuration. |
| `opencode-only/instructions/shell-strategy.md` | OpenCode-only | Non-interactive shell strategy and cognitive standards. | Specific to OpenCode's unique non-interactive runtime environment. |
| `opencode/agents/code-simplifier.md` | Agent | Persona for simplifying complex code patterns. | A specialized agent definition used by OpenCode. |

## Decision Framework

When adding new instructions, use the following criteria to determine the appropriate location:

### 1. `shared/instructions/`
**Use when**:
*   The instruction is about the **repository's domain** (e.g., Nix conventions, project structure).
*   The instruction applies to **all AI tools** regardless of their runtime limitations.
*   Example: "General coding standards for Nix flakes".

### 2. `{tool}-only/instructions/`
**Use when**:
*   The instruction addresses a **limitation or feature unique to one tool** (e.g., OpenCode's lack of TTY, Claude Code's MCP tools).
*   The instruction provides **cognitive strategies** specific to how a tool processes information.
*   Example: "Claude Code MCP tool usage patterns".

### 3. `{tool}/agents/`
**Use when**:
*   You are defining a **specialized persona or expert agent** for a specific tool.
*   The instruction is a **pre-configured prompt** for a recurring task (e.g., refactoring, documentation).

## Adding New Instructions

To add a new instruction file:

1.  **Identify the category** using the [Decision Framework](#decision-framework).
2.  **Create the markdown file** in the appropriate directory:
    *   `shared/instructions/new-instruction.md`
    *   `opencode-only/instructions/new-instruction.md`
    *   `claude-code-only/instructions/new-instruction.md`
3.  **Update the implementation**:
    *   If it's a shared instruction, it should be included in the `common-instructions` list in `default.nix`.
    *   If it's tool-specific, update the corresponding tool's configuration to include the new file.
4.  **Format the content** for maximum effectiveness:
    *   Use clear headers and bullet points.
    *   Provide **Positive Constraints** (e.g., "ALWAYS USE: X" instead of "Don't use Y").
    *   Include **BAD vs GOOD** examples for clarity.

## References

*   `modules/home-manager/features/ai-tools/default.nix`: Main configuration for instruction inclusion.
*   `modules/home-manager/features/ai-tools/opencode/default.nix`: OpenCode-specific instruction injection logic.
