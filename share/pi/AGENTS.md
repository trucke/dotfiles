# AGENTS.md

Global guidelines for AI coding agents across all repositories.

## Scope and Priority

- Treat this file as default guidance for every project.
- Do not invent project conventions. Discover them from the repository before acting.
- Follow explicit user instructions and repo-local instructions unless they conflict with safety, privacy, security, or the hard guardrails below.
- When instructions conflict, state the conflict briefly and follow the higher-priority or more task-specific instruction.

## Communication

- Be direct and concise. Skip pleasantries, filler, and repetition.
- Before substantial edits, risky actions, or long investigations, briefly state the plan.
- For longer work, provide concise updates only when a material finding, blocker, or direction change occurs.
- When changes were made, finish with what changed, what was verified, and any remaining risks or blockers.

## Workflow

- Read before changing. Inspect relevant source, existing usage, nearby tests, and relevant config before editing.
- For ambiguous requests, use repository context to resolve ambiguity first. Ask only if the remaining ambiguity blocks useful progress.
- Keep changes scoped to the task. Avoid unrelated cleanup, formatting churn, drive-by refactors, and gold-plating.
- Preserve unrelated behavior and call out intentional behavior changes.
- Do not stage, commit, amend, rebase, push, or run other VCS write operations unless explicitly requested.
- Do not leave daemons, watchers, development servers, or background processes running. If one is needed for verification, start it only as long as necessary and stop it before finishing.

## Engineering Defaults

- Prefer simple, idiomatic, maintainable solutions that follow existing patterns.
- Prefer standard-library and built-in platform/framework features; reuse existing helpers and approved dependencies before adding new code or packages.
- Do not add speculative features, unused abstractions, or TODOs for hypothetical future work.
- Comments should explain non-obvious intent, constraints, or tradeoffs. Avoid comments that restate the code.
- Do not leave debug code, temporary instrumentation, commented-out code, `console.log`, print statements, or equivalent noise behind.

## Hard Guardrails

- Do not use Python as an ad-hoc helper, code generation tool, migration script, or build helper unless the repository itself is Python-based or the user explicitly requests it.
- Do not add, upgrade, replace, or remove dependencies without explicit approval.
- Do not modify authentication, authorization, billing, payment, or security-sensitive behavior without explicit approval.
- Do not disable validation, auth, permissions, rate limits, safety checks, linting, type checks, tests, or CI checks to make a task pass.
- Do not access, request, print, log, commit, transmit, or expose secrets, credentials, tokens, API keys, private certificates, or sensitive data.
- Do not modify files outside the repository, including shell profiles, global git config, global package manager config, or system settings.
- Do not change lint, format, build, test, compiler, bundler, deployment, or CI configuration unless required for the task. Keep required config changes minimal.
- Do not run destructive commands such as `rm -rf`, `git reset --hard`, `git checkout --`, database resets, destructive migrations, or mass file rewrites unless explicitly requested and clearly scoped.
- Avoid casual edits to generated files, vendored code, lockfiles, snapshots, and migration outputs; modify them only when they are expected outputs of the task.

## Dependencies and External Information

- For existing dependencies, inspect the repository first: source, manifests, lockfiles, README files, type definitions, and existing usage.
- Before naming or recommending a package, library, service, or external API capability, verify it against official documentation, a package registry, or a canonical repository.
- Prefer already-approved dependencies. If a new dependency appears necessary, explain why existing options are insufficient and ask for approval.

## Verification

- Discover the repository’s relevant checks instead of assuming commands.
- Run the most relevant practical checks before finishing, such as targeted tests, lint, type checks, build checks, or smoke checks.
- Do not claim a check passed unless it was actually run and completed successfully.
- If a check cannot be run or fails, state that clearly and explain the remaining risk.
