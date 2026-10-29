"""PreToolUse hook: block any tool call whose input contains a personal identifier listed in ~/.claude/identifiers.txt.
The list stays on the user's machine, outside the repo. One identifier per line; lines starting with # are ignored.
Exit 2 blocks the call and returns the message to Claude. Limit: it matches text as written, not encoded or split values.
"""
import json, sys
from pathlib import Path

payload = json.load(sys.stdin)
cfg = Path.home() / ".claude" / "identifiers.txt"
if not cfg.exists():
    print(f"identifier guard: {cfg} is missing, so nothing is checked", file=sys.stderr)
    sys.exit(0)
ids = [l.strip().lower() for l in cfg.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")]
text = json.dumps(payload.get("tool_input", {}), ensure_ascii=False).lower()
for i in ids:
    if i in text:
        print("blocked: this call contains one of the user's protected identifiers. Do not send it anywhere; ask the user first.", file=sys.stderr)
        sys.exit(2)
sys.exit(0)
