# Roblox animation pipeline. Method by fwjelaa (FWJ STUDIOS). See CREDITS.md.
"""Uploads exported animations to Roblox through Open Cloud (Assets API v1) and prints their asset ids.

    python -I kit/upload.py R6_M1_1 [R6_M1_2 ...]      upload out/<Name>.rbxmx as Animation assets

Setup (see "Automatic upload" in GUIDE.md):
  - Your Open Cloud API key goes in .secrets/roblox-api-key.txt (or the ROBLOX_API_KEY environment variable),
    with the Assets API, Read + Write. It is only ever sent as the x-api-key header and never printed.
  - config.json says who owns the uploads: "group_id" (your group) or "user_id" (your account).

Roblox has accepted animation uploads through Open Cloud since 2025-10-23: a .rbxm or .rbxmx whose root is a
KeyframeSequence, sent with the content type model/x-rbxm (for both). Ids are saved to out/uploads.json and
written into out/AnimationIds.luau for your game scripts.
"""
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "out"
API = "https://apis.roblox.com/assets/v1"


def load_key() -> str:
    key = os.environ.get("ROBLOX_API_KEY", "").strip()
    path = ROOT / ".secrets" / "roblox-api-key.txt"
    if not key and path.exists():
        key = path.read_text(encoding="utf-8").strip()
    if not key:
        sys.exit("No API key: put it in .secrets/roblox-api-key.txt (see Automatic upload in GUIDE.md).")
    return key


def load_config() -> dict:
    path = ROOT / "config.json"
    config = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    group, user = str(config.get("group_id", "")).strip(), str(config.get("user_id", "")).strip()
    if group:
        creator = {"groupId": group}
    elif user:
        creator = {"userId": user}
    else:
        sys.exit("config.json needs a group_id or a user_id (see Automatic upload in GUIDE.md).")
    return {"creator": creator, "prefix": config.get("name_prefix", "")}


def upload(path: pathlib.Path, display: str, description: str, creator: dict, key: str):
    def redact(text: str) -> str:
        return text.replace(key, "[redacted]")

    def request(method, url, body=None, content_type=None):
        req = urllib.request.Request(url, data=body, method=method)
        req.add_header("x-api-key", key)
        if content_type:
            req.add_header("Content-Type", content_type)
        try:
            with urllib.request.urlopen(req, timeout=120) as res:
                return res.status, json.loads(res.read() or b"{}")
        except urllib.error.HTTPError as err:
            return err.code, {"error": redact(err.read().decode("utf-8", "replace"))[:500]}

    meta = {
        "assetType": "Animation",
        "displayName": display[:50],
        "description": description[:1000],
        "creationContext": {"creator": creator},
    }
    boundary = uuid.uuid4().hex
    body = b"".join([
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n".encode(),
        (f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{path.name}\"\r\n"
         f"Content-Type: model/x-rbxm\r\n\r\n").encode() + path.read_bytes() + b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ])
    status, res = request("POST", f"{API}/assets", body, f"multipart/form-data; boundary={boundary}")
    if status >= 300:
        return {"name": path.stem, "status": status, "error": res.get("error", res)}
    operation = res.get("path") or res.get("operationId")
    for _ in range(60):  # uploads finish asynchronously: poll the operation
        if res.get("done"):
            break
        time.sleep(2)
        status, res = request("GET", f"{API}/{operation}")
        if status >= 300:
            return {"name": path.stem, "status": status, "error": res.get("error", res)}
    asset_id = (res.get("response") or {}).get("assetId")
    if not asset_id:
        return {"name": path.stem, "status": status, "error": redact(json.dumps(res))[:500]}
    return {"name": path.stem, "assetId": asset_id}


def main():
    names = sys.argv[1:]
    if not names:
        sys.exit(__doc__)
    key, config = load_key(), load_config()
    ids_path = OUT / "uploads.json"
    ids = json.loads(ids_path.read_text(encoding="utf-8")) if ids_path.exists() else {}
    for name in names:
        path = OUT / f"{name}.rbxmx"
        if not path.exists():
            print(json.dumps({"name": name, "error": f"{path.name} not found: export it first"}))
            continue
        result = upload(path, config["prefix"] + name, f"{name} (fwjelaa animation method)", config["creator"], key)
        if "assetId" in result:
            ids[name] = result["assetId"]
        print(json.dumps(result), flush=True)
    ids_path.write_text(json.dumps(ids, indent=2), encoding="utf-8")
    lines = ["-- Animation ids uploaded by kit/upload.py. Put this ModuleScript in ReplicatedStorage.", "return {"]
    lines += [f'\t{n} = "rbxassetid://{i}",' for n, i in sorted(ids.items())]
    (OUT / "AnimationIds.luau").write_text("\n".join(lines + ["}", ""]), encoding="utf-8")


if __name__ == "__main__":
    main()
