---
description: Generate and apply a commit message from current changes
model: opencode/gpt-5-nano
temperature: 0.1
subtask: true
agent: commit
---

Generate a commit message from current changes and commit them. Prefer jj over git when available.

Detection:
- Use bash to check if `jj` is available and if `.jj/` directory exists in the repo.
- If jj is available and repo has `.jj/`, use jj workflow below.
- Otherwise, use git workflow below.

For jj workflow:
- Use bash to run `jj diff` to get the diff of current changes.
- If no changes, reply exactly: `No changes found (working tree is clean).`
- Generate commit message from the diff.
- Use bash to run `jj commit -m "<commit_message>"` to commit the change and create a new working commit automatically.
- Use bash to run `jj log -r @-` to show the newly created commit.

For git workflow:
- Use bash to run `git diff --cached` (staged changes) first.
  - If non-empty, use only this diff to generate the message.
  - Commit using `git commit -m "<message>"` (already staged).
  - Use bash to run `git log -1 --stat` to show the newly created commit.
- If staged diff is empty, run `git diff` (unstaged changes).
  - If non-empty, stage all changes with `git add -A`, then commit with the generated message.
  - Use bash to run `git log -1 --stat` to show the newly created commit.
- If both are empty, reply exactly: `No staged or unstaged changes found (working tree is clean).`

Commit message format (no extra text, no headings):

- Line 1: short, imperative summary of the overall change.
- Line 2: blank.
- Then `- ` bullets, each describing a concrete change.

Target style (structure only):

    Summarize the main change in a short, imperative sentence

    - Describe an important functional change
    - Mention a behavior change or new capability
    - Highlight a notable refactor or cleanup
    - Point out removed or deprecated parts if relevant
    - Note important configuration or documentation updates

Guidelines:
- Focus on "what + why", group related changes when possible.
- Ignore pure formatting / generated / lock files unless they are the only changes.
- Default: no Conventional Commit prefixes.
  - If the user asks for Conventional Commits, use `type(scope?): summary`
    on line 1, keep the bullets the same.
- Report what command was run and the resulting commit/bookmark status.
