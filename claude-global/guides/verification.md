# Success criteria and verification

Pick the rows that fit; combine for mixed tasks. A criterion says what must be true. A check says how you'll establish it.

## Rules

- Inspect existing state before changing it. Verify the final version with the smallest sufficient checks plus required project checks.
- Use my stated targets. Otherwise state assumptions; don't invent numeric targets.
- Add durable tests only when they protect real behavior. Don't re-run passing checks without a reason.
- Screenshot = appearance only. Build = compiles only. Samples ≠ all-case correctness. If an environment is unavailable, say which verification is missing.
- Separate pre-existing failures from ones you introduced.
- Never weaken criteria to pass. If scope changes, say so.
- Finish with each required criterion marked **met / unmet / unverified**, grouped concisely. Claim full completion only when all required criteria are met.
- A blocked validator (e.g. missing Python module) is not a pass. Name the limitation and describe what you checked directly.

## Software

| Task | Must be true | Evidence |
|---|---|---|
| Feature | Behavior works, edge/failure cases behave, existing behavior intact | Focused tests or runs (expected vs actual); build/lint/types |
| Bug fix | Reported trigger now works; neighbors still fine | Reproduce before, rerun after; regression test; say if repro unavailable |
| Refactor | Structure changed, behavior and public interfaces preserved | Before/after runs; diff review for stray functional changes |
| Algorithm/contest | Matches spec, handles edges, fits complexity | Samples, boundaries, correctness argument, brute-force compare |
| UI / frontend | Flows work in relevant viewports/states; keyboard and a11y intact | Rendered inspection, interaction, screenshots; check focus, labels, loading/empty/error. Separate DOM/JSDOM checks from real-browser QA, and respect reduced-motion paths |
| API / integration | Contract, auth, failure behavior correct; consumers compatible | Current contract docs, sanitized responses, contract tests |
| Data / migration | Records and invariants preserved, rollback/idempotency as needed | Counts, checksums, dry run |
| Config / dependency | Valid config, lockfile agrees, workflow runs | Parser validation, lockfile diff, build |
| Performance | Metric meets target or improves over baseline, correctness intact | Same-workload before/after, repeat runs |
| Security / privacy | Named threat mitigated, legit use works, secrets protected | Threat scenario, positive and negative tests; state coverage limits |
| Build / release / deploy | Right artifact/version exists, target runs it, smoke passes | Build output, version refs, status. Local build ≠ deployed. Sync every manifest and keep existing updater signing keys; confirm target version first |
| Repo / file op | Paths and state exist, references resolve, unrelated work kept | status/diff/tree; remote state if remote op requested |

## Thinking, documents, external work

| Task | Must be true | Evidence |
|---|---|---|
| Planning | Goal and constraints met, tradeoffs, risks, open decisions explicit | Trace requirements to deliverables; check feasibility vs real project |
| Research | Questions answered, claims sourced, recommendation follows criteria | Primary sources, dated URLs, cross-check disputed claims |
| Analysis / math / spreadsheet | Inputs and units right, results reproducible | Independent recalculation, formula/range inspection, inspect charts/exports |
| Code / doc review | Scope inspected, findings have location/trigger/consequence | File:line refs; "no findings" states scope and gaps |
| Documentation | Accurate, scoped, links resolve, commands checked or labeled unrun | Diff review, link check |
| Design / media / slides / PDF | Meets brief, renders correctly, I can open it | Open the real output; for PDFs inspect every page, render when needed |
| External action | Right account/resource, no duplicates, nothing unrelated changed | Read back from the service; record IDs/URLs |
| Explanation | Actual question answered at my level; facts correct | Worked example or source; no ceremonial commands |

## Evidence style

Commands and outcomes, file:line refs, citations, expected vs actual, read-back state. No raw log dumps or secrets. If a check fails: diagnose, fix within scope, rerun affected checks. Don't skip failures or invent passes.
