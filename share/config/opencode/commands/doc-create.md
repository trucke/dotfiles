---
description: Create comprehensive documentation from source code analysis (for developers or leadership)
model: anthropic/claude-opus-4-6
---

Create thorough, accurate documentation for a given topic by analyzing the actual source code.

## Input

Topic or description: `$ARGUMENTS`

If `$ARGUMENTS` is empty, ask the user what they want documented.

### Source document

If `$ARGUMENTS` references an existing documentation file (e.g., `/doc-create leadership overview from docs/auth-flow.md`), use that file as the primary source:

- Read and understand the source document first.
- Use it as the structural foundation — don't research from scratch.
- Verify key claims against actual source code before rewriting.
- Adapt the content for the target audience.

### Audience

Detect the audience from `$ARGUMENTS` (look for keywords like "overview", "leadership", "PM", "lead", "high-level", "executive"). If unclear, ask.

- **developer** (default): Technical documentation for engineers.
- **leadership**: High-level documentation for leads and PMs.

## Workflow

### 1. Clarify scope

Before any research, evaluate whether the topic is clear enough to produce useful documentation. If ambiguous or broad, ask the user **concise, specific** clarifying questions. Examples:

- Which parts of the system should this cover?
- Should it include usage examples, architecture details, or both?

If the topic is already specific and actionable, skip clarification and proceed.

### 2. Source code research

Do a thorough review of the codebase to gather accurate implementation details:

- Identify all relevant files, modules, and entry points related to the topic.
- Trace execution paths, data flow, and key abstractions.
- Note public APIs, configuration options, important types/interfaces, and error handling.
- Check for existing documentation, comments, README files, and AGENTS.md files that provide context.
- Verify claims against actual code — do not guess or hallucinate implementation details.
- If you cannot find the implementation for something relevant to the topic, surface the gap to the user before writing. Never fill in blanks with assumptions.

Use the explore agent and grep/glob tools extensively. Prioritize accuracy over speed.

### 3. Write documentation

Produce a well-structured markdown document with these qualities:

- **Accurate**: Every technical claim backed by source code.
- **Complete**: Covers the topic end-to-end without leaving gaps.
- **Human-readable**: Clear prose, logical flow, good use of headings, lists and tables.
- **Concise**: No filler or repetition. Dense with useful information.

Structure guidelines (all audiences):

- Start with a brief overview (1-3 sentences: what it is, why it exists).
- Use descriptive headings that help scanning.
- End with any caveats, limitations, or related areas worth exploring.

#### Developer audience

- Include concrete examples, code snippets, and configuration references where helpful.
- Reference relevant source files (e.g., `src/auth/middleware.ts`) so readers can dig deeper. Do not include line numbers — they go stale quickly.
- Add examples for non-obvious usage patterns.
- Cover public APIs, types/interfaces, error handling, and edge cases.
- Consider including where relevant: responsibilities/scope, internal flow, failure modes, data model, configuration, extension points. Omit any that don't apply — never pad empty sections.

#### Leadership audience

- Focus on architecture, system design, key decisions, and tradeoffs.
- Cover important runtime behaviors (data flow, error handling strategy, scaling characteristics) without implementation detail.
- Include configuration details only where they are critical to understanding the system.
- No code snippets or source file references.
- Use clear, non-jargon language where possible. Define technical terms when unavoidable.
- Emphasize the "why" behind decisions: constraints, tradeoffs, alternatives considered.

### 4. Save

- **Developer docs**: Save to `docs/` (e.g., `docs/authentication-flow.md`).
- **Leadership docs**: Save to `docs/overview/` (e.g., `docs/overview/authentication.md`).
- Create the target directory if it does not exist.
- Choose a descriptive, kebab-case filename that reflects the content.
- Write the file and report the path to the user.
