---
name: status-audit
description: Strict audit of STATUS.md against tests, spec, plan, and implementation
model: opencode/kimi-k2.5
temperature: 0.1
subtask: true
agent: audit
---

Audit project progress from `${1:-STATUS.md}`.

Workflow (strict, in order):
1) Read and understand `${1:-STATUS.md}` fully.
2) Run tests as sanity check **only if a test command is clearly discoverable**.
   - If no test command is discoverable, skip tests silently (no output line, no warning).
3) Parse spec + implementation plan paths from STATUS file list (example: `Files: specs/x.md specs/plan-x.md`).
4) Validate both paths exist.
   - If either path is missing from STATUS, or either file path does not exist: **exit immediately with FAIL**.
5) Read the spec and audit STATUS claims against spec status/requirements.
6) Read the implementation plan.
7) Review code in files referenced by STATUS and/or implementation plan.
8) Audit code + plan against STATUS:
   - Verify each claimed completed task.
   - Flag incomplete work, mismatches, behavior drift.
9) Produce concise report.

Hard rules:
- Never infer, assume, or guess spec/plan.
- Never continue on missing/invalid spec/plan paths.
- Do not modify files.
- Do not commit.
- Use precise file/line references for findings.

Output format (strict):
- Verdict: PASS | PARTIAL | FAIL
- Checks:
  - [PASS] <task/claim>
  - [PARTIAL] <task/claim> — <one-line reason>
  - [FAIL] <task/claim> — <one-line reason>
- Mismatches:
  - `<path:line>` — <issue>
- Keep output concise, no fluff.

Conditional output rule:
- Include `Tests: <result>` only if tests were actually run.
- If tests were skipped due to no discoverable command, output nothing about tests.
