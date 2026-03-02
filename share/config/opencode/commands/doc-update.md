---
description: Update existing documentation by reviewing source code for drifts and changes
model: anthropic/claude-sonnet-4-6
---

Review and update an existing documentation file by comparing it against the current source code.

## Input

Documentation file path: `${1}`
Optional focus/instructions: `$ARGUMENTS` (everything after the file path)

If no path is provided, ask the user which documentation file to update.
If additional context is provided, use it to focus the review (e.g., "focus on the new OAuth changes"). Otherwise, do a full audit of the entire document.

## Workflow

### 1. Read and understand the document

- Read the entire documentation file.
- Identify what topics, modules, APIs, and behaviors it covers.
- Note its structure, tone, and level of detail to maintain consistency when updating.
- Detect the target audience from the document's location and content:
  - `docs/overview/` or high-level non-technical content → **leadership** audience.
  - `docs/` or technical content with code references → **developer** audience.
  - When updating, maintain the document's audience-appropriate style (e.g., no code snippets in leadership docs, no jargon without definitions).

### 2. Source code review

Thoroughly review the source code that the document describes:

- Identify all files, modules, and entry points referenced or implied by the document.
- Compare documented behavior against actual implementation.
- Look for (in priority order):
  1. **Drift**: Documented behavior that no longer matches the code.
  2. **Missing coverage**: New features, APIs, options, or behaviors not yet documented.
  3. **Stale references**: File paths, function names, or config keys that have changed or been removed.
  4. **Inaccuracies**: Statements that were never correct or are now misleading.
  5. **Quality issues**: Unclear prose, poor structure, or readability problems (secondary to accuracy).

Use the explore agent and grep/glob tools extensively. Verify every claim in the document against the code. If you cannot verify a claim from the source, flag it as unverifiable rather than assuming it is correct or incorrect.

If the document is accurate and up-to-date, report that and stop. Do not manufacture changes.

### 3. Present changes for approval

Before modifying anything, present a clear summary of proposed changes to the user:

```
## Proposed Documentation Updates

### Corrections
- [section/line] What changed and why

### Additions
- [section] New content to add and why

### Removals
- [section/line] What to remove and why
```

Keep each item to 1-2 lines. Be specific about what will change and where. Reference source files to justify each change.

**Wait for user approval before proceeding.** Do not apply changes until the user confirms. The user may approve all changes, or exclude specific items (e.g., "apply all except the removal in section X"). Respect their selection.

### 4. Apply changes

After approval:

- Apply all approved changes to the document.
- Maintain the document's existing structure, tone, and formatting conventions.
- Do not rewrite sections that are still accurate — keep diffs minimal.
- Report what was updated.
