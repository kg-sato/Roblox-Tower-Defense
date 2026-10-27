"""Upload a local file to Roblox with the official Open Cloud Assets API, then print the new asset id.
Replaces the manual Asset Manager import for: Model (.fbx .gltf .glb .rbxm), Image/Decal (.png .jpg .bmp .tga),
Audio (.mp3 .ogg .wav .flac), Animation (.rbxm .rbxmx), Video (.mp4 .mov).
Docs: https://create.roblox.com/docs/cloud/guides/usage-assets  (POST https://apis.roblox.com/assets/v1/assets,
then poll GET /assets/v1/operations/{id} until done; 20 MB per call; audio 100/month if ID-verified, 10 if not).

SAFETY: dry run by default (shows what would be sent, sends nothing). A real upload needs BOTH --upload and the
owner's OK. The API key is read only from the environment variable ROBLOX_API_KEY and is never printed or written.
Create the key yourself at https://create.roblox.com/dashboard/credentials (Assets: read+write), then in PowerShell:
   $env:ROBLOX_API_KEY = "<paste key>"      (current window only)
Usage (Hunyuan3D venv has requests):
   Hunyuan3D/.venv/Scripts/python.exe -I tools/upload_asset.py <file> --user <yourUserId> [--name N] [--desc D] [--upload]
Results are appended to tools/uploads.json (file, type, asset id, time) so ids can be wired into the game."""
import sys, os, json, time, argparse, mimetypes

TYPES = {
    ".fbx": ("Model", "model/fbx"), ".gltf": ("Model", "model/gltf+json"), ".glb": ("Model", "model/gltf-binary"),
    ".png": ("Decal", "image/png"), ".jpg": ("Decal", "image/jpeg"), ".jpeg": ("Decal", "image/jpeg"),
    ".bmp": ("Decal", "image/bmp"), ".tga": ("Decal", "image/tga"),
    ".mp3": ("Audio", "audio/mpeg"), ".ogg": ("Audio", "audio/ogg"), ".wav": ("Audio", "audio/wav"), ".flac": ("Audio", "audio/flac"),
    ".mp4": ("Video", "video/mp4"), ".mov": ("Video", "video/mov"),
    ".rbxmx": ("Animation", "model/x-rbxm"),
}
LIMIT = 20 * 1024 * 1024

ap = argparse.ArgumentParser()
ap.add_argument("file")
ap.add_argument("--user", required=True, help="your Roblox user id (creator)")
ap.add_argument("--group", help="group id instead of user (key must be created under the group)")
ap.add_argument("--type", help="override asset type, e.g. Animation or Model for .rbxm")
ap.add_argument("--name"); ap.add_argument("--desc", default="")
ap.add_argument("--upload", action="store_true", help="actually send it (default is a dry run)")
a = ap.parse_args()

ext = os.path.splitext(a.file)[1].lower()
if ext == ".rbxm":
    kind, ctype = (a.type or "Model"), "model/x-rbxm"
elif ext in TYPES:
    kind, ctype = TYPES[ext]
    kind = a.type or kind
else:
    sys.exit(f"unsupported file type {ext}")
size = os.path.getsize(a.file)
if size > LIMIT:
    sys.exit(f"{a.file} is {size/1e6:.1f} MB; the API limit is 20 MB per call")
name = (a.name or os.path.splitext(os.path.basename(a.file))[0])[:50]
creator = {"groupId": a.group} if a.group else {"userId": a.user}
request = {"assetType": kind, "displayName": name, "description": a.desc, "creationContext": {"creator": creator}}
print(f"{'UPLOAD' if a.upload else 'DRY RUN'}: {a.file} ({size/1e6:.2f} MB) as {kind} [{ctype}] name={name!r} creator={creator}")
if not a.upload:
    print("nothing sent. Add --upload (with the owner's OK) to send.")
    sys.exit(0)

key = os.environ.get("ROBLOX_API_KEY")
if not key:
    sys.exit("ROBLOX_API_KEY is not set in this shell")
import requests
with open(a.file, "rb") as f:
    r = requests.post("https://apis.roblox.com/assets/v1/assets", headers={"x-api-key": key},
                      files={"request": (None, json.dumps(request)), "fileContent": (os.path.basename(a.file), f, ctype)}, timeout=120)
if r.status_code >= 300:
    sys.exit(f"create failed: HTTP {r.status_code} {r.text[:300]}")
op = r.json().get("path") or r.json().get("operationId")
op_id = op.split("/")[-1]
asset_id = None
for _ in range(60):
    g = requests.get(f"https://apis.roblox.com/assets/v1/operations/{op_id}", headers={"x-api-key": key}, timeout=30)
    body = g.json()
    if body.get("done"):
        asset_id = (body.get("response") or {}).get("assetId")
        if not asset_id:
            sys.exit(f"operation finished without an asset id: {json.dumps(body)[:300]}")
        break
    time.sleep(2)
if not asset_id:
    sys.exit(f"timed out waiting for operation {op_id}; check later with the same operation id")
print(f"asset id {asset_id}  ->  rbxassetid://{asset_id}")
log = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads.json")
data = json.load(open(log)) if os.path.exists(log) else []
data.append({"file": a.file, "type": kind, "assetId": asset_id, "time": time.strftime("%Y-%m-%d %H:%M")})
json.dump(data, open(log, "w"), indent=1)
