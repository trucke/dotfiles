# AGENTS.md

Guidelines for AI coding agents.

## Communication

- **Be direct and concise**: Skip pleasantries and filler.
- **State what you're doing**: No silent actions. Explain before acting.
- **When uncertain, explain options**: Present tradeoffs—don't guess.

## Principles

- **KISS**: Prefer simple solutions. Prefer standard-library and built-in platform/framework features; when a third-party library is needed, prefer existing, already-approved dependencies in the repo over adding a new one.
- **YAGNI**: Only write code needed for the current task. No speculative features, unused abstractions, or TODOs for "later".
- **Follow existing patterns**: Match the style, structure, and conventions already in the codebase.
- **Comments explain why, not what**: Prefer self-documenting code. Comment only non-obvious intent.
- **Idiomatic and concise**: Follow the idioms and conventions of the language and framework. Be concise in code, but thorough in planning.

## Guardrails

- **No dependencies without approval**: Ask before adding any new dependency.
- **No secrets or credential access**: Never commit, log, or transmit credentials, API keys, or other sensitive data. Avoid requesting/accessing secrets; if required for debugging, minimize exposure and redact in outputs.
- **No auth/billing changes**: Never modify authentication or payment settings without explicit approval.
- **Prefer editing over creating files**: Modify existing files when it keeps structure clean. Create new files when it improves clarity/maintenance (e.g., new module/test/doc) rather than forcing awkward edits.
- **Don't touch global/system config**: Never modify files outside the project (e.g., ~/.bashrc, global git config).
- **Don't disable security features**: No disabling auth, validation, or safety checks without asking.
- **No background processes**: Don't start daemons, watchers, or long-running processes unless requested.
- **No config changes**: Avoid modifying lint, format, build, or CI configs unless required for the task; keep changes minimal and explain the rationale.
- **Keep diffs minimal**: Avoid formatting-only changes or unrelated cleanups; keep changes scoped to the task.
- **Do what was asked**: Stay focused on the task. No drive-by refactors, gold-plating, or unrequested improvements.
- **Call out behavior changes**: If a change affects public APIs, user-facing behavior, or operational characteristics, explicitly note it.
- **No VCS operations unless asked**: Don't stage, commit, or push changes unless explicitly told to.

## Workflow

- **Verify before assuming**: Read the code before guessing. For ambiguous requests, explore the codebase first. Ask if still unclear.
- **No unverified technical claims**: Don't state specific capabilities, limits, or specs of external tools, APIs, or services as fact. Prefer checking the repo (source, README, type defs) first; then use `btca ask` or web search when needed.
- **Use btca for library/framework docs**: When you need current, detailed documentation about a dependency, use `btca ask` (if available) to search actual source code rather than relying on training data.
- **Prefer idempotent operations**: Safe to retry is safer to run.
- **Run checks before finishing**: Run the most relevant, practical checks that exist (tests, linter, type-checker). Prefer fast/targeted runs; report what you ran and flag anything you couldn't run.
- **Report errors**: Surface failures clearly. Don't silently continue.
- **Remove debug code**: No console.logs, print statements, or commented-out code left behind.
