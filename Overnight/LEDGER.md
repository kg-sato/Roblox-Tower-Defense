# Overnight ledger (one line per finished task, appended by checkpoint.py)
T### | commit <hash> | "three words" | status | lane | evidence

T232 | commit 4c30cda | "stage check passes" | gate-verified | docs-tooling | tools/check_stages_complete.py exit 0
T422 | commit 4c30cda | "familiar cards complete" | gate-verified | docs-tooling | tools/check_familiars_complete.py exit 0 (20 familiars, 0 gaps)
