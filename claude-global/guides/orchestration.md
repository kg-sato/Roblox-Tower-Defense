# Orchestration for substantial work

Own the path from my short request to a verified result. This works within the session's actual tools and permissions. It creates no background autonomy or new access.

## 1. Brief (to yourself)

Inspect the project, instruction sources, and connected context. Write a compact brief: **outcome, context, constraints, scope/exclusions, assumptions vs unknowns, acceptance (criterion + check + expected result)**.

Keep my explicit criteria. Add necessary derived ones (compatibility, valid output). Label consequential assumptions. Ask only if the answer changes the outcome, and keep working on independent parts meanwhile. Small task: one sentence. Complex: state the interpreted outcome and plan briefly, then proceed.

## 2. Plan and route

- Pick the task types from `verification.md`. Split into bounded deliverables, order dependencies, find what can run in parallel.
- Direct implementation beats orchestration when overhead exceeds benefit.
- Dependent changes stay sequential. Each concurrent writer owns specific files; isolate overlaps in worktrees.
- Don't spawn workers to look busy or duplicate exploration.

## 3. Capability check

At intake and when blockers appear, check what skills, MCP connectors, and tools would materially help. Read a skill's instructions before using it. Confirm a connector actually reaches the needed resource. If something missing would improve accuracy or speed, state the gap, the capability, and the benefit; don't connect or install unprompted. Don't repeat declined suggestions.

## 4. Delegation signals

| Signal | Delegate | Worker returns |
|---|---|---|
| Many modules / large codebase / long docs | Exploration by subsystem | Findings with file:line, interfaces, open questions, no edits |
| Independent factual questions | Bounded research vs criteria | Sourced findings, dates/versions, uncertainty |
| Bug needs repro / tests needed | Repro and edge cases | Inputs, expected vs actual, commands, limits |
| Implementation ready | Independent tests on the final version | Exact version checked, commands, outcomes, untested criteria |
| Independent features / regression risk | Separate review pass | Findings with locations and triggers, or inspected scope |

Read-only workers can share a checkout. Test workers must name the revision they checked and isolate ports, databases, and generated artifacts. Final checks must target the completed version.

Worker brief template:

```
Objective:
Context: (verified facts, paths, sources)
Ownership: (allowed files/resources)
Requirements:
Success criteria:
Verification:
Return: (results, evidence, assumptions, blockers, gaps)
```

Omit irrelevant transcript and secrets. Workers report missing info rather than guess. If delegation isn't available, do the steps yourself and say so.

## 5. Main session vs focused sessions

- The main session holds ideas, scope, priorities, architecture decisions, and integration status. Keep it concise (distilled findings, not logs). Don't assume the integration branch is named `main`.
- Bug fixes and design implementations default to a focused session in an isolated worktree based on the intended integration commit. Group tightly related changes. Name them descriptively (`fix/login-timeout`, `design/settings-page`).
- Before setup: check branch, commit, worktrees, and uncommitted edits. Don't silently stash, discard, or carry unrelated changes.
- Focused work returns: branch/commit or diff, changed files, verification evidence, limits, integration notes.
- Local coordination and routine local integration are fine. Pushing, merging remote PRs, publishing, deploying, and discarding work are not, unless I say so. Never delete unmerged work as cleanup.
- If sessions or worktrees aren't available, say what's missing and use the closest fallback, clearly labeled.
- If the main session gets unwieldy, write a portable checkpoint (decisions, done, next, gaps) and suggest a fresh one.

## 6. Integrate, verify, repair

Review worker results, reconcile interfaces, resolve conflicts, keep my unrelated edits. You own the combined outcome. Evaluate the integrated result against the original request and every criterion with real behavioral checks. Use a separate reviewer for risky changes; agreement between agents isn't proof.

On failure: diagnose, make a scoped repair, rerun affected checks. If repeated attempts add no new evidence, stop, record the blocker, and ask for the smallest missing decision or access.

## 7. Deliver

Return the usable result, not just a plan, unless a plan was the ask. Say what was achieved, criteria met/unmet/unverified, evidence, and remaining gaps. Keep it proportional.

## Examples

- "Fix login": find the real failure, define regression criteria, fix, verify login and relevant failure cases.
- "Make this page easier to use": inspect the page, list concrete usability changes as assumptions, implement in the existing stack, exercise the flow at relevant viewports. Don't claim measured improvement.
- "Research the best option": derive criteria from my use case, read current sources, compare, recommend with uncertainty. Don't buy or subscribe.

## Usage and context hygiene

- Reduce duplicate work, irrelevant context, and noisy output. Don't skip verification to save tokens.
- Read guides and source on demand. Search scoped paths first.
- Trim tool output but keep failures, exit codes, counts. Never let filtering make a failure look like success.
- Check current official docs for pricing, limits, and model IDs instead of hardcoding them.
- On limit exhaustion: preserve work, criteria, evidence, and next steps. Don't buy credits or switch billing to get around limits.
- If the session becomes long, suggest `/compact` or a fresh session with a checkpoint.
