# AGENTS.md

Guidelines for AI coding agents.

## Communication

- **Be direct and concise**: Skip pleasantries and filler.
- **State what you're doing**: No silent actions. Explain before acting.
- **When uncertain, explain options**: Present tradeoffs—don't guess.

## Principles

- **KISS**: Prefer simple solutions. Use built-in language/framework features over custom abstractions.
- **YAGNI**: No code for hypothetical futures. Delete unused code. No TODOs for "later".
- **Follow existing patterns**: Match the style, structure, and conventions already in the codebase.
- **Comments explain why, not what**: Prefer self-documenting code. Comment only non-obvious intent.
- **Functional and concise**: Prefer functional programming patterns. Be concise in code, but thorough in planning.

## Guardrails

- **No dependencies without approval**: Ask before adding any new dependency.
- **No secrets in code**: Never commit credentials, API keys, or sensitive data.
- **No credential access**: Don't read, log, or transmit API keys or tokens.
- **No auth/billing changes**: Never modify authentication or payment settings without explicit approval.
- **Don't modify unrelated code**: Stay focused on the task. No drive-by refactors.
- **Prefer editing over creating files**: Modify existing files when possible. Avoid file sprawl.
- **Don't touch global/system config**: Never modify files outside the project (e.g., ~/.bashrc, global git config).
- **Don't disable security features**: No disabling auth, validation, or safety checks without asking.
- **Ask before large changes**: Architectural decisions, new patterns, or changes spanning many files require approval.
- **No background processes**: Don't start daemons, watchers, or long-running processes unless requested.
- **No config changes**: Don't modify lint, format, build, or CI configs unless requested.
- **Do what was asked**: Complete the task as specified. No gold-plating or unrequested improvements.
- **Stick to defined schemas**: When specs, PRDs, or other docs define a data model (fields, types, values), use exactly those fields. Do not invent, rename, or extend fields that aren't in the source of truth.

## Workflow

- **Verify before assuming**: Read the code before guessing how it works.
- **Research, then ask**: For ambiguous requests, explore the codebase first. Ask if still unclear.
- **Web search for tools/tech**: When comparing or choosing tools and technologies, always search the web.
- **No unverified technical claims**: Don't state specific capabilities, limits, or specs of external tools, APIs, or services as fact. Research first, then cite what you found.
- **Prefer idempotent operations**: Safe to retry is safer to run.
- **Run checks before finishing**: Run tests, linter, and type-checker if they exist.
- **Fix errors when they occur**: Attempt to fix build/test failures. Ask if the fix requires architectural changes.
- **Report errors**: Surface failures clearly. Don't silently continue.
- **Remove debug code**: No console.logs, print statements, or commented-out code left behind.
- **Commit only when asked**: Stage changes but don't commit unless explicitly requested.

## Version Control

- **Prefer jj over git**: If both exist (colocated repo), use jj. For new projects, use jj.
- **Git fallback**: Use git only when jj is not available.

## Specs workflow

- Specs live in `specs/` with a flat structure and kebab-case filenames.
- Status lifecycle: Proposal -> Draft -> Ready -> Implemented.
- Only implement when the spec is Ready; update status to Implemented after shipping.
