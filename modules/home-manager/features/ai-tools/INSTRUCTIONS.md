# AI Tools Instruction Management

This document provides guidance on managing instructions for AI tools (Claude Code, OpenCode) within this repository. The instruction abstraction layer ensures that AI agents receive the most relevant and efficient guidelines based on their specific tool, profile, and environment.

## Overview

The instruction management system uses a tiered approach to organize and deliver instructions:

1.  **Shared Instructions** (`general/instructions/`): General guidelines applicable to all AI tools and profiles.
2.  **Tool-Specific Instructions** (`opencode/instructions/`, `claude-code/instructions/`): Specialized rules or strategies unique to a specific tool's runtime or capabilities.
3.  **Agent/Persona Definitions** (`opencode/agents/`, `claude-code/agents/`): Specialized behavioral instructions for specific tasks or domains.

## Current Instruction Inventory

| File Path | Category | Profile Scope | Purpose | Why it's here |
| :--- | :--- | :--- | :--- | :--- |
| `general/instructions/nix-environment.md` | Shared | All | Nix environment awareness and ad-hoc package usage. | Applies to any AI tool running in this Nix-managed configuration. |
| `opencode/instructions/shell-strategy.md` | OpenCode-specific | All | Non-interactive shell strategy and cognitive standards. | Specific to OpenCode's unique non-interactive runtime environment. |
| `opencode/agents/code-simplifier.md` | Agent | All | Persona for simplifying complex code patterns. | A specialized agent definition used by OpenCode. |

## Decision Framework

When adding new instructions, use the following criteria to determine the appropriate location:

### 1. `general/instructions/`
**Use when**:
*   The instruction is about the **repository's domain** (e.g., Nix conventions, project structure).
*   The instruction applies to **all AI tools and profiles** regardless of their runtime limitations.
*   Example: "General coding standards for Nix flakes", "Environment setup for developers".

### 2. `opencode/instructions/`
**Use when**:
*   The instruction addresses a **limitation or feature unique to OpenCode** (e.g., non-interactive environment, TTY constraints).
*   The instruction provides **cognitive strategies** specific to how OpenCode processes information.
*   Example: "OpenCode shell non-interactive strategy", "Handling CI/CD in headless environments".

### 3. `claude-code/instructions/`
**Use when**:
*   The instruction addresses a **limitation or feature unique to Claude Code** (e.g., MCP tool usage, browser automation).
*   The instruction provides **cognitive strategies** specific to Claude Code's capabilities.
*   Example: "Claude Code MCP server patterns", "Browser automation with Claude Code".

### 4. `opencode/agents/` or `claude-code/agents/`
**Use when**:
*   You are defining a **specialized persona or expert agent** for a specific tool.
*   The instruction is a **pre-configured prompt** for a recurring task (e.g., refactoring, documentation).
*   Example: "Code-simplifier agent", "Documentation-generator agent".

## Adding New Instructions

To add a new instruction file:

1.  **Identify the category** using the [Decision Framework](#decision-framework).
2.  **Create the markdown file** in the appropriate directory:
    *   `general/instructions/new-instruction.md` - Shared across tools
    *   `opencode/instructions/new-instruction.md` - OpenCode-specific
    *   `claude-code/instructions/new-instruction.md` - Claude Code-specific
    *   `opencode/agents/new-agent.md` - OpenCode agent personas
    *   `claude-code/agents/new-agent.md` - Claude Code agent personas
3.  **Update the implementation**:
    *   For shared instructions: Include in both `opencode/default.nix` and `claude-code/default.nix` settings.instructions
    *   For tool-specific instructions: Include in the corresponding tool's `default.nix` settings.instructions
4.  **Format the content** for maximum effectiveness:
    *   Use clear headers and bullet points.
    *   Provide **Positive Constraints** (e.g., "ALWAYS USE: X" instead of "Don't use Y").
    *   Include **BAD vs GOOD** examples for clarity.
    *   For profile-specific instructions, document which profiles they apply to.

## Profile-Based Instruction Delivery

Instructions are delivered to all profiles uniformly. When instructions need to reference profile-specific behaviors:

1. Document both behaviors in the same instruction
2. Use examples that show profile-specific paths (e.g., "work profile: mac-m1-max", "personal profile: framework-16")
3. Create separate instruction files for genuinely profile-specific guidance

## References

*   `modules/home-manager/features/ai-tools/default.nix`: Main configuration for instruction inclusion.
*   `modules/home-manager/features/ai-tools/opencode/default.nix`: OpenCode-specific instruction injection and profile-based filtering.
*   `modules/home-manager/features/ai-tools/claude-code/default.nix`: Claude Code-specific instruction injection and profile-based skill filtering.
