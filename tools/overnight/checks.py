"""Named verification checks the gate can run without Studio. Protected: Claude cannot change what 'pass' means.
  python tools/overnight/checks.py <name>     names: compile, export, hygiene"""
import py_compile, subprocess, sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]


def compile_all():
    bad = []
    for p in list((root / "tools").glob("*.py")) + list((root / "Audio").glob("*.py")) + list((root / "UI Kit").rglob("*.py")):
        try:
            py_compile.compile(str(p), doraise=True)
        except Exception as e:
            bad.append(f"{p}: {e}")
    return bad


def export():
    d = root / "Studio_Export"
    need = {"GameClient.luau": 2500, "MatchService.luau": 150, "MatchSim.luau": 300, "Config.luau": 200, "UltFX.luau": 100}
    bad = []
    for name, lines in need.items():
        f = d / name
        if not f.exists():
            bad.append(f"missing {name}")
        elif len(f.read_text(encoding="utf-8", errors="replace").splitlines()) < lines:
            bad.append(f"{name} has fewer than {lines} lines")
    return bad


def hygiene():
    bad = []
    changed = subprocess.run(["git", "diff", "--name-only", "HEAD"], cwd=root, capture_output=True, text=True).stdout.splitlines()
    for f in changed:
        if f.startswith(("Kimi/", "ComfyUI/", ".claude/skills/")) or f.endswith(".rbxl"):
            bad.append("forbidden path changed: " + f)
    tests = (root / "Tests").glob("*.luau")
    for t in tests:
        s = t.read_text(encoding="utf-8", errors="replace")
        if "check(" not in s:
            bad.append(f"{t.name} has no checks")
    return bad


fn = {"compile": compile_all, "export": export, "hygiene": hygiene}.get(sys.argv[1] if len(sys.argv) > 1 else "")
if not fn:
    sys.exit("usage: checks.py compile|export|hygiene")
problems = fn()
print("PASS" if not problems else "FAIL\n" + "\n".join(problems))
sys.exit(1 if problems else 0)
