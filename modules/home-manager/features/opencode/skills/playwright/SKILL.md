---
name: playwright
description: Browser automation via Playwright MCP tools. Use when AI Agent needs to interact with web browsers for: (1) Web scraping and data extraction, (2) Form interaction and submission, (3) Browser testing and validation, (4) Taking screenshots of web pages, or any browser automation tasks.
---

# Playwright MCP Browser Automation

## Core Workflow

```
navigate → snapshot → interact → snapshot → close
```

## Tool Selection

| Tool | Use Case |
|------|----------|
| `playwright_browser_navigate` | Open URL |
| `playwright_browser_snapshot` | Read page structure (preferred over screenshot) |
| `playwright_browser_take_screenshot` | Capture visual state |
| `playwright_browser_click` | Click elements |
| `playwright_browser_type` | Type text into elements |
| `playwright_browser_fill_form` | Batch fill multiple form fields |
| `playwright_browser_select_option` | Select dropdown options |
| `playwright_browser_press_key` | Keyboard shortcuts |
| `playwright_browser_drag` | Drag and drop |
| `playwright_browser_hover` | Mouse hover |
| `playwright_browser_evaluate` | Execute JavaScript |
| `playwright_browser_file_upload` | Upload files |
| `playwright_browser_handle_dialog` | Handle alerts/confirms |
| `playwright_browser_wait_for` | Wait for text/disappear/timer |
| `playwright_browser_tabs` | Tab management (list/new/close/select) |
| `playwright_browser_console_messages` | Check for errors |
| `playwright_browser_network_requests` | Inspect network traffic |
| `playwright_browser_run_code` | Run Playwright code snippets |

## Best Practices

**Order matters**:
1. `navigate` to URL
2. `snapshot` to find elements (use `ref` from output)
3. `wait_for text` to ensure load
4. Interact with `ref` from snapshot
5. Repeat `snapshot` to track changes
6. `close` when done

**Form filling**: Use `fill_form` with fields array (each needs `name`, `type`, `ref`, `value`).

**Element references**: Always use `ref` from `snapshot` output - never guess selectors.

**Dialogs**: Call `handle_dialog` with `accept: true/false` before triggering action.

**Errors**: Check `console_messages(onlyErrors=true)` before completing.

**Screenshots**: Only use when visual inspection needed. Use `snapshot` for structure.

**Multiple tabs**: Use `tabs(action="new/select/close")` with `index` for close/select.