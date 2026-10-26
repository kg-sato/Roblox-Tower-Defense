"""Headless runner: the same kit without the Blender MCP (Blender runs in the background).

    python kit/run.py check               is Blender (and Pillow, for reference sheets) ready?
    python kit/run.py make R6_Run         build anims/R6_Run.py, export to out/, run the checks
    python kit/run.py sheet R6_Run [view] [--frames 0,6,9]
                                          make + contact sheet out/sheet_R6_Run_<view>.png
    python kit/run.py video R6_Run [view] make + MP4 in out/video/
    python kit/run.py reel A B C [--view back] [--title Combo]
                                          several clips back to back as one MP4 (out/video/<title>_<view>.mp4)
    python kit/run.py all                 make every anims/*.py

  Reference clips (a video, a GIF, one picture or a folder of pictures):
    python kit/run.py ref <clip> <Name> [--every N] [--from F] [--to F] [--fps F]
                                          frames into ref/<Name>/ + a labelled timing sheet ref/sheet_<Name>.png
    python kit/run.py compare <Name> [--ref RefName] [--start F] [--speed K] [--view V] [--frames a,b,c]
                                          reference frames over the animation's matching frames:
                                          out/compare_<Name>.png (clip frame F = animation frame 0)

Views: front, three_quarter, side, back (the player's camera), back_three_quarter, top, or yaw:<deg>[:<pitch>]
to match a reference camera (yaw 0 front, 90 the character's right side, 180 behind).
"""
import glob
import json
import os
import shutil
import subprocess
import sys

KIT = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.dirname(KIT)
VIDEO = (".mp4", ".mov", ".webm", ".gif", ".mkv", ".avi", ".m4v", ".wmv")
IMAGE = (".png", ".jpg", ".jpeg", ".webp", ".bmp")


def find_blender():
    if os.environ.get("BLENDER"):
        return os.environ["BLENDER"]
    found = shutil.which("blender")
    if found:
        return found
    candidates = sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender *\blender.exe"), reverse=True)
    candidates += ["/Applications/Blender.app/Contents/MacOS/Blender"]
    return next((c for c in candidates if os.path.exists(c)), None)


def blender(code):
    exe = find_blender()
    if not exe:
        sys.exit("Blender not found. Install Blender 4.2+ from blender.org or set the BLENDER variable.")
    # start from an empty scene (no default cube, camera or light)
    script = (f"import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)\n"
              f"import sys; sys.path.insert(0, {KIT!r}); import live\n{code}")
    proc = subprocess.run([exe, "-b", "--factory-startup", "--python-expr", script],
                          capture_output=True, text=True, encoding="utf-8", errors="replace")
    lines = [ln for ln in proc.stdout.splitlines() if not ln.startswith(("Blender ", "Read prefs", "Fra:", "Saved:", "Time:"))]
    out = "\n".join(lines).strip()
    if proc.returncode != 0 or "Traceback" in proc.stdout + proc.stderr:
        print(out[-3000:])
        print(proc.stderr[-3000:])
        sys.exit("Blender run failed (the traceback above names the line).")
    return out


def take(args, flag, cast=str, default=None):
    """Pop `--flag value` out of args."""
    if flag in args:
        i = args.index(flag)
        value = cast(args[i + 1])
        del args[i:i + 2]
        return value
    return default


def pillow():
    try:
        from PIL import Image, ImageDraw, ImageFont  # noqa: F401
    except ImportError:
        sys.exit("Pillow is missing: run  python -m pip install pillow  and try again.")
    return Image, ImageDraw, ImageFont


def font(size):
    _, _, ImageFont = pillow()
    for path in (r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\arialbd.ttf",
                 "/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial Bold.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def grid(cells, cols, path, cell_w=480):
    """cells = [(PIL image, label)]; writes a labelled grid PNG."""
    Image, ImageDraw, _ = pillow()
    f = font(22)
    cell_h = max(round(img.height * cell_w / img.width) for img, _ in cells)
    label_h = 38
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * (cell_h + label_h)), (22, 23, 27))
    draw = ImageDraw.Draw(sheet)
    for i, (img, label) in enumerate(cells):
        img = img.convert("RGB").resize((cell_w, round(img.height * cell_w / img.width)))
        r, c = divmod(i, cols)
        x, y = c * cell_w, r * (cell_h + label_h)
        sheet.paste(img, (x, y))
        draw.text((x + 10, y + cell_h + 7), label, fill=(240, 236, 228), font=f)
    sheet.save(path)
    return path


def ref(args):
    """python kit/run.py ref <clip|picture|folder> <Name> [--every N] [--from F] [--to F] [--fps F]"""
    Image, _, _ = pillow()
    every, first, last = take(args, "--every", int, 0), take(args, "--from", int, 0), take(args, "--to", int)
    fps_given = take(args, "--fps", float)
    src, name = os.path.abspath(args[0]), args[1]
    folder = os.path.join(PACK, "ref", name)
    os.makedirs(folder, exist_ok=True)
    ext = os.path.splitext(src)[1].lower()
    if os.path.isdir(src) or ext in IMAGE:
        pics = sorted(p for p in glob.glob(os.path.join(src, "*")) if p.lower().endswith(IMAGE)) \
            if os.path.isdir(src) else [src]
        for old in glob.glob(os.path.join(folder, "frame_*.png")):
            os.remove(old)
        for n, p in enumerate(pics):
            Image.open(p).convert("RGB").save(os.path.join(folder, f"frame_{n:04d}.png"))
        info = {"source": os.path.basename(src), "fps": fps_given or 0, "frames": len(pics), "step": 1,
                "extracted": list(range(len(pics))), "pictures": True}
        with open(os.path.join(folder, "info.json"), "w", encoding="utf-8") as fh:
            json.dump(info, fh, indent=1)
    elif ext in VIDEO:
        shutil.copy2(src, os.path.join(folder, "source" + ext))
        out = blender(f"import reference; import json; print('INFO', json.dumps(reference.extract("
                      f"{src!r}, {folder!r}, step={every}, start={first}, end={last!r})))")
        info = json.loads(out.split("INFO", 1)[1].strip().splitlines()[0])
        if fps_given:
            info["fps"] = fps_given
    else:
        sys.exit(f"Don't know how to read {ext or 'that'}: use a video (mp4, mov, webm, gif), a picture or a folder.")
    fps = info["fps"]
    cells = []
    for n in info["extracted"]:
        img = Image.open(os.path.join(folder, f"frame_{n:04d}.png"))
        if fps:
            label = f"clip f{n}  {n / fps:.2f}s  = anim f{round(n * 60 / fps)}"
        else:
            label = f"picture {n + 1}"
        cells.append((img, label))
    sheet = grid(cells, 6 if len(cells) > 12 else 4, os.path.join(PACK, "ref", f"sheet_{name}.png"), cell_w=400)
    print(f"REFERENCE {name}: {info['source']}, {info['frames']} frames"
          + (f" at {fps:g} fps = {info['frames'] / fps:.2f}s; every {info['step']} frame(s) extracted" if fps else
             " (pictures: key poses, no timing)"))
    print(f"  sheet: {sheet}")
    if fps:
        print(f"  timing: clip frame n -> animation frame n * 60 / {fps:g} (labels show it). If the clip is slowed down "
              "or sped up, say so and scale the timing.")


def compare(args):
    """python kit/run.py compare <Name> [--ref RefName] [--start F] [--speed K] [--view V] [--frames a,b,c]"""
    Image, _, _ = pillow()
    name = args[0]
    ref_name = take(args, "--ref", str, name)
    start = take(args, "--start", int, None)
    speed = take(args, "--speed", float, 1.0)
    view = take(args, "--view", str, "three_quarter")
    wanted = take(args, "--frames", str, None)
    folder = os.path.join(PACK, "ref", ref_name)
    if not os.path.exists(os.path.join(folder, "info.json")):
        sys.exit(f"No reference called {ref_name}: run  python kit/run.py ref <clip> {ref_name}  first.")
    info = json.load(open(os.path.join(folder, "info.json"), encoding="utf-8"))
    have = info["extracted"]
    start = have[0] if start is None else start
    picks = [int(n) for n in wanted.split(",")] if wanted else [n for n in have if n >= start]
    if not wanted and len(picks) > 8:
        picks = [picks[round(i * (len(picks) - 1) / 7)] for i in range(8)]
    picks = [min(have, key=lambda h: abs(h - n)) for n in picks]  # nearest extracted frame
    fps = info["fps"]
    meta = json.loads(blender(f"import json; live.make({name!r}); import bpy; "
                              f"print('META', json.dumps(json.loads(bpy.data.objects[{name!r}]['rbx_anim'])))")
                      .split("META", 1)[1].strip().splitlines()[0])
    length = meta["length"]
    if info.get("pictures"):  # no timing: spread the pictures evenly over the animation
        anim = [round(i * length / max(1, len(picks) - 1)) for i in range(len(picks))]
    else:
        anim = [round((n - start) / fps * 60 * speed) for n in picks]
        anim = [a % (length + 1) if meta["loop"] else max(0, min(length, a)) for a in anim]
    first_ref = Image.open(os.path.join(folder, f"frame_{picks[0]:04d}.png"))
    size = (480, max(240, round(480 * first_ref.height / first_ref.width)))  # same shape as the reference
    out = blender(f"import json; live.make({name!r}); "
                  f"print('PATHS', json.dumps(live.compare_frames({name!r}, {sorted(set(anim))!r}, {view!r}, {size!r})))")
    paths = {int(k): v for k, v in json.loads(out.split("PATHS", 1)[1].strip().splitlines()[0]).items()}
    cells = []
    for n in picks:
        label = f"reference f{n}" + (f"  {n / info['fps']:.2f}s" if info["fps"] else "")
        cells.append((Image.open(os.path.join(folder, f"frame_{n:04d}.png")), label))
    for n, a in zip(picks, anim):
        cells.append((Image.open(paths[a]), f"animation f{a}"))
    path = grid(cells, len(picks), os.path.join(PACK, "out", f"compare_{name}.png"), cell_w=360)
    shutil.rmtree(os.path.join(PACK, "out", "_compare"), ignore_errors=True)
    print(f"COMPARE {name} vs reference {ref_name}: top row reference, bottom row animation ({view} view)")
    print(f"  {path}")
    print("  pairs: " + ", ".join(f"clip f{n} -> anim f{a}" for n, a in zip(picks, anim)))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "check":
        print(blender("import bpy; print('BLENDER OK', bpy.app.version_string)"))
        try:
            import PIL
            print("PILLOW OK", PIL.__version__)
        except ImportError:
            print("PILLOW MISSING (only needed for reference clips): python -m pip install pillow")
    elif cmd == "make":
        print(blender(f"print(live.make({args[0]!r}))"))
    elif cmd == "sheet":  # python kit/run.py sheet R6_M1_1 side [--frames 0,4,6,8]
        frames = take(args, "--frames", lambda s: [int(f) for f in s.split(",")])
        view = args[1] if len(args) > 1 else "three_quarter"
        print(blender(f"print(live.make({args[0]!r})); print(live.sheet({args[0]!r}, {view!r}, frames={frames!r}))"))
    elif cmd == "video":
        view = args[1] if len(args) > 1 else "three_quarter"
        print(blender(f"print(live.make({args[0]!r})); print(live.video({args[0]!r}, {view!r}))"))
    elif cmd == "reel":
        view = take(args, "--view", str, "three_quarter")
        title = take(args, "--title")
        print(blender(f"print(live.reel({args!r}, {view!r}, title={title!r}))"))
    elif cmd == "ref":
        ref(args)
    elif cmd == "compare":
        compare(args)
    elif cmd == "all":
        for path in sorted(glob.glob(os.path.join(PACK, "anims", "*.py"))):
            name = os.path.splitext(os.path.basename(path))[0]
            if not name.startswith("_"):  # _lib, _m1... are shared helpers, not animations
                print(blender(f"print(live.make({name!r}))"))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
