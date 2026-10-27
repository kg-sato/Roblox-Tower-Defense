"""Scene-detect + dense burst + motion curve for a video, using only ffmpeg and the Python standard library.
   python tools/video_scenes.py <video> <out_dir> [--thresh 0.3] [--burst-fps 10] [--burst-sec 1.0] [--spikes 6]
Writes to <out_dir>:
  motion.csv           time_s, scene_score (0..1 frame-to-frame change) for every frame
  scenes.txt           cut times (score >= thresh) and the strongest motion spikes
  keys/                one keyframe per cut
  burst_NN_<t>s/       dense frames (burst-fps) from burst-sec before to burst-sec after each cut/spike
  sheet_NN_<t>s.jpg    contact sheet of each burst (time-labelled by file name order)
Uses the ffmpeg on PATH. Local files only; nothing is uploaded. Combine with tools/record_window.py for Studio clips."""
import sys, os, re, subprocess, argparse

ap = argparse.ArgumentParser()
ap.add_argument("video"); ap.add_argument("out")
ap.add_argument("--thresh", type=float, default=0.3)
ap.add_argument("--burst-fps", type=float, default=10)
ap.add_argument("--burst-sec", type=float, default=1.0)
ap.add_argument("--spikes", type=int, default=6, help="extra bursts at the strongest non-cut motion spikes")
a = ap.parse_args()
os.makedirs(a.out, exist_ok=True)

def run(args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-y"] + args, capture_output=True, text=True)

# 1. per-frame scene score
r = run(["-i", a.video, "-vf", "select='gte(scene,0)',metadata=print:file=-", "-an", "-f", "null", "-"])
times, scores, t = [], [], None
for line in r.stdout.splitlines():
    m = re.search(r"pts_time:([\d.]+)", line)
    if m: t = float(m.group(1))
    m = re.search(r"lavfi.scene_score=([\d.]+)", line)
    if m and t is not None:
        times.append(t); scores.append(float(m.group(1)))
if not times:
    sys.exit("no frames read: " + r.stderr[-400:])
with open(os.path.join(a.out, "motion.csv"), "w") as f:
    f.write("time_s,scene_score\n")
    for x, s in zip(times, scores): f.write(f"{x:.3f},{s:.4f}\n")
dur = times[-1]

# 2. cuts and spikes
cuts = [x for x, s in zip(times, scores) if s >= a.thresh]
cuts = [x for i, x in enumerate(cuts) if i == 0 or x - cuts[i - 1] > 0.3]
rest = sorted(((s, x) for x, s in zip(times, scores) if s < a.thresh and s > 0.05), reverse=True)
spikes = []
for s, x in rest:
    if all(abs(x - y) > a.burst_sec for y in cuts + spikes):
        spikes.append(x)
    if len(spikes) >= a.spikes: break
with open(os.path.join(a.out, "scenes.txt"), "w") as f:
    f.write(f"duration {dur:.2f}s, frames {len(times)}, avg fps {len(times)/max(dur,1e-6):.1f}\n")
    f.write(f"cuts (score >= {a.thresh}): " + ", ".join(f"{x:.2f}" for x in cuts) + "\n")
    f.write("motion spikes: " + ", ".join(f"{x:.2f}" for x in sorted(spikes)) + "\n")

# 3. keyframes + bursts + sheets
os.makedirs(os.path.join(a.out, "keys"), exist_ok=True)
events = [(x, "cut") for x in cuts] + [(x, "spike") for x in spikes]
events.sort()
if not events or events[0][0] > 0.5: events.insert(0, (0.0, "start"))
for i, (x, kind) in enumerate(events):
    tag = f"{i:02d}_{x:.2f}s"
    run(["-ss", f"{x:.3f}", "-i", a.video, "-frames:v", "1", os.path.join(a.out, "keys", f"{tag}_{kind}.jpg")])
    b0 = max(0.0, x - a.burst_sec)
    bd = os.path.join(a.out, f"burst_{tag}")
    os.makedirs(bd, exist_ok=True)
    run(["-ss", f"{b0:.3f}", "-t", f"{2*a.burst_sec:.3f}", "-i", a.video, "-vf", f"fps={a.burst_fps},scale=360:-2",
         os.path.join(bd, "f_%03d.jpg")])
    cols = 5
    n = len(os.listdir(bd))
    rows = max(1, -(-n // cols))
    run(["-framerate", "1", "-i", os.path.join(bd, "f_%03d.jpg"), "-vf", f"tile={cols}x{rows}", "-frames:v", "1",
         os.path.join(a.out, f"sheet_{tag}.jpg")])
print(f"{os.path.basename(a.video)}: {dur:.1f}s, {len(cuts)} cuts, {len(spikes)} spikes -> {a.out}")
print("Burst frames start at t =", "; ".join(f"{max(0,x-a.burst_sec):.2f}" for x, _ in events), f"(every {1/a.burst_fps:.2f}s)")
