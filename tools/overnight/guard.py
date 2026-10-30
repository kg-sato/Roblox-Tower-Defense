"""PreToolUse hook for unattended runs. Inert unless Overnight/ACTIVE exists.
While armed it answers every tool call with allow or deny, never ask, so nothing waits for a click.
Allow = what the user has already said yes to (local edits, tests, Studio MCP, reading docs).
Deny = anything outside the policy in Overnight/POLICY.md. Every denial is appended to Overnight/denials.log.
This is a guardrail, not a sandbox: a determined script can get around text checks. The stop gate restores
tampered control files, and the real fix for strong isolation is a separate Windows user or VM."""
import json, os, re, sys, time
from pathlib import Path

payload = json.load(sys.stdin)
project = Path(payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or ".").resolve()
root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or project).resolve()
if not (root / "Overnight" / "ACTIVE").exists():
    sys.exit(0)

tool = payload.get("tool_name", "")
inp = payload.get("tool_input") or {}
home = Path.home()
ALLOWED_ROOTS = [
    root,
    home / "AppData" / "Local" / "Temp",
    home / ".claude" / "projects" / "C--Users-kgsat-Documents-Roblox",
    home / ".claude" / "guides",
    home / "Downloads" / "blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release",  # Blender exe (user, 2026-10-29: tools outside the folder may run)
]
PROTECTED = [
    root / ".claude" / "settings.json",
    root / ".claude" / "settings.local.json",
    root / "tools" / "overnight",
    root / "Overnight" / "POLICY.md",
    root / "Overnight" / "ACTIVE",
    root / "Overnight" / "denials.log",
]
READ_ONLY_DIRS = [root / "Kimi", root / "ComfyUI", root / "Animation Kit", root / "Hunyuan3D" / "Hunyuan3D-2"]


def under(p, base):
    try:
        Path(p).resolve().relative_to(Path(base).resolve())
        return True
    except Exception:
        return False


def decide(allow, why):
    if not allow:
        try:
            with open(root / "Overnight" / "denials.log", "a", encoding="utf-8") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {tool} {json.dumps(inp)[:300]} -> {why}\n")
        except Exception:
            pass
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow" if allow else "deny",
        "permissionDecisionReason": ("[overnight] " + why),
    }}))
    sys.exit(0)


def path_ok(p, write):
    if not p:
        return True, ""
    rp = Path(p) if os.path.isabs(p) else root / p
    if not any(under(rp, r) for r in ALLOWED_ROOTS):
        return False, f"path outside the project: {p}"
    low = str(rp).lower()
    if re.search(r"(^|[\\/])(\.env[^\\/]*|id_rsa[^\\/]*|\.ssh|\.aws|\.npmrc|\.netrc|credentials\.json)([\\/]|$)", low):
        return False, "secret-looking path"
    if write:
        if any(under(rp, b) or rp == b for b in PROTECTED):
            return False, "protected control file"
        if any(under(rp, d) for d in READ_ONLY_DIRS):
            return False, "third-party folder, read-only"
        if rp.suffix.lower() == ".rbxl":
            return False, "place file is saved by the user, not edited on disk"
    return True, ""


LOOPBACK = re.compile(r"^https?://(127\.0\.0\.1|localhost|\[::1\])([:/]|$)", re.I)

SHELL_DENY = [
    (r"\bgit\s+(push|reset|rebase|clean|filter-branch|update-ref|commit|merge|pull|fetch|remote|config|add|stash|tag|cherry-pick|revert|am|apply|worktree|submodule|gc|prune|restore|rm|mv)\b", "git writes go through tools/overnight/checkpoint.py"),
    (r"\bgit\s+(checkout|switch)\b", "no branch switching"),
    (r"\bgit\s+branch\s+(-[a-zA-Z]*[dDmM]|--delete|--move)", "no branch deletion"),
    (r"\b(pip3?|uv|cargo|npm|yarn|pnpm|winget|choco|scoop)\b.*\b(install|add|i|upgrade|update)\b|\bnpx\b|\buvx\b|python\S*\s+-m\s+pip", "no new dependencies"),
    (r"\b(gh|glab|az|aws|gcloud|supabase|wrangler|vercel|netlify|firebase|ssh|scp|ftp|telnet|nc|ncat)\b", "external service CLI"),
    # upload_asset.py is allowed: the user pre-approved uploads on 2026-10-28.
    (r"install-for-codex|(?:^|[;&|]\s*)(?:publish|deploy)\b|\b(?:npm|yarn|pnpm|vercel|netlify|firebase|wrangler)\s+(?:run\s+)?(?:publish|deploy)\b", "publish and deploy need the user"),
    (r"\b(shutdown|Restart-Computer|Stop-Computer|logoff|schtasks|netsh|setx|icacls|takeown|Set-ExecutionPolicy|Set-MpPreference|Add-MpPreference|reg\s+(add|delete|import))\b", "system or security setting"),
    (r"\b(Stop-Process|taskkill|kill|pkill)\b.*(Studio|Roblox|claude|explorer|node|MsMpEng|Defender)", "must not stop Studio, Claude or system processes"),
    (r"\.env\b|id_rsa|[\\/]\.ssh\b|[\\/]\.aws\b|\.npmrc|\.netrc|credentials\.json|api[_-]?key\s*=|Login Data|OPEN_?CLOUD|ROBLOX_API", "secret access"),
    (r"(Remove-Item|\brm\b|\bdel\b|\brmdir\b|\brd\b|\berase\b).*(-r\b|-rf\b|-fr\b|-Recurse|/s\b)", "recursive delete"),
]
NET = re.compile(r"\b(curl|wget|Invoke-WebRequest|iwr|Invoke-RestMethod|irm|Start-BitsTransfer|certutil|bitsadmin)\b", re.I)
URL = re.compile(r"https?://[^\s\"')]+", re.I)
# Hosts the user approved for downloads (2026-10-27): public CC0 or free asset sources only, https only.
HOSTS = ("unity3d.com", "unity.com", "particlefx.studio", "annomotion.studio", "opengameart.org", "creativecommons.org")


DATA_EXT = (".png", ".jpg", ".jpeg", ".webp", ".glb", ".gltf", ".fbx", ".obj", ".wav", ".ogg", ".mp3", ".flac", ".json", ".md", ".txt", ".lua", ".luau", ".zip", ".csv")


def data_ok(u):
    """User, 2026-10-29: https downloads of plain data files from public hosts are allowed (never executables or installers); the file lands in the project like any other write."""
    m = re.match(r"https://[^/:?#]+/([^?#]*)", u, re.I)
    return bool(m) and m.group(1).lower().endswith(DATA_EXT)


def host_ok(u):
    m = re.match(r"https://([^/:?#]+)", u, re.I)
    return bool(m) and any(m.group(1).lower() == h or m.group(1).lower().endswith("." + h) for h in HOSTS)

SELF_OK = re.compile(r"python\S*\s+[\"']?(\./)?tools[\\/]overnight[\\/](checkpoint|checks)\.py[\"']?[^;&|\n]*", re.I)
SELF_TOUCH = re.compile(r"tools[\\/]overnight|\.claude[\\/]settings|Overnight[\\/](POLICY|ACTIVE|denials)|overnight_protected", re.I)
ABS = re.compile(r"(?<![\w])[A-Za-z]:[\\/][^\s\"'|;&<>]*")


def check_shell(cmd):
    stripped = SELF_OK.sub("", cmd)
    if SELF_TOUCH.search(stripped):
        return False, "touches overnight control files"
    for pat, why in SHELL_DENY:
        if re.search(pat, cmd, re.I):
            return False, why
    if NET.search(cmd):
        urls = URL.findall(cmd)
        if not urls or not all(LOOPBACK.match(u) or host_ok(u) or data_ok(u) for u in urls):
            return False, "network access beyond localhost and the approved download hosts"
    for m in ABS.findall(cmd):
        if not any(under(m.rstrip("\\/."), r) for r in ALLOWED_ROOTS):
            return False, f"path outside the project: {m}"
    return True, ""


LUAU_DENY = re.compile(
    r"PromptPurchase|PromptProductPurchase|PromptGamePassPurchase|PublishAsync|SaveToRoblox|PublishAs|CreateAssetAsync|"
    r"CreateAssetVersionAsync|UploadAsset|PromptImportFiles|game:Shutdown|:Kick\(|MessagingService|"
    r"HttpService\s*:\s*(Post|Request)Async|HttpService\s*:\s*GetAsync\(\s*[\"'](?!https?://(127\.0\.0\.1|localhost))",
    re.I,
)

if tool in ("Bash", "PowerShell"):
    ok, why = check_shell(inp.get("command", ""))
    decide(ok, why or "shell command in policy")
if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
    ok, why = path_ok(inp.get("file_path") or inp.get("notebook_path"), True)
    decide(ok, why or "edit inside the project")
if tool in ("Read", "Glob", "Grep"):
    ok, why = path_ok(inp.get("file_path") or inp.get("path"), False)
    decide(ok, why or "read inside the project")
if tool in ("WebFetch", "WebSearch"):
    decide(True, "read-only research; the result is untrusted data")
if tool in ("ToolSearch", "Skill", "TodoWrite", "ReadNotifications", "Agent", "Task", "TaskStop", "Monitor") or tool.startswith("mcp__ccd_turn__"):
    decide(True, "session tool")
if tool == "mcp__ccd_session__mark_chapter" or tool == "mcp__ccd_host__request_keep_awake":
    decide(True, "session tool")
if tool == "mcp__roblox-studio__execute_luau":
    m = LUAU_DENY.search(inp.get("code", ""))
    decide(not m, f"Luau uses {m.group(0)}" if m else "Studio script in policy")
if tool == "mcp__roblox-studio__http_get":
    decide(bool(LOOPBACK.match(inp.get("url", ""))), "localhost only")
# Uploads, Creator Store inserts and Studio AI generation are pre-approved by the user (2026-10-28) and fall through to "Studio MCP".
if tool in ("mcp__roblox-studio__subagent", "mcp__roblox-studio__skill"):
    decide(True, "Studio subagent and skill calls allowed since 2026-10-29")
if tool.startswith("mcp__roblox-studio__"):
    decide(True, "Studio MCP")
if tool.startswith("mcp__terminal__"):
    decide(False, "use the shell tools so the guard can see commands")
decide(False, f"{tool}: external account, browser, desktop control or unknown tool; not part of the overnight policy")
