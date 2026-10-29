"""Whole-screen "looks premium" metrics (2026-10-28). The user: our loading screen, skill tree and level path "still feel
lower quality than the other games ... I can't quantify the visual difference". This puts numbers on it.

    python -I tools/look_quality.py <label=image> [<label=image> ...]      one row per image

  hard     share of pixels on a hard edge (Sobel > 0.35): cut-out vector shapes score high; painted, glowing art low
  halo     glow falloff: area at mid brightness (0.12..0.45) next to bright cores (> 0.7), divided by the core area.
           Bloom / soft light has a wide halo (> 3); flat neon has almost none (< 1)
  grain    texture in the dark, flat areas: mean |Laplacian| where the image is dark and has no edge. Real art,
           film grain, dust and noise give texture; an empty flat fill gives ~0
  levels   distinct luminance levels used (of 64): smooth gradients and many layers use many; flat fills use few
  band     banding in smooth areas: share of smooth-area neighbours that step by exactly one 8-bit level in long
           runs; high = visible stair-steps in a gradient
  sat      mean saturation of non-dark pixels, and huesd: spread of hue, i.e. how many colours share the screen
  vign     vignette: mean brightness of the outer 15% ring / the centre 40%; < 0.6 = darkened edges that focus the eye
  dof      blur variety: spread (std) of local sharpness across the frame; depth of field and soft backgrounds raise it
"""
import sys
import cv2
import numpy as np


def metrics(path):
    im = cv2.imread(path)
    if im is None:
        raise SystemExit("cannot read " + path)
    h, w = im.shape[:2]
    s = 900 / max(h, w)
    im = cv2.resize(im, (int(w * s), int(h * s)), interpolation=cv2.INTER_AREA)
    f = im.astype(np.float32) / 255
    lum = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY).astype(np.float32) / 255
    gx, gy = cv2.Sobel(lum, cv2.CV_32F, 1, 0, ksize=3), cv2.Sobel(lum, cv2.CV_32F, 0, 1, ksize=3)
    grad = np.sqrt(gx * gx + gy * gy)
    hard = float((grad > 0.35).mean())
    core = lum > 0.7
    ring = cv2.dilate(core.astype(np.uint8), np.ones((31, 31), np.uint8)).astype(bool) & ~core
    mid = (lum > 0.12) & (lum < 0.45)
    halo = float((ring & mid).sum() / max(1, core.sum()))
    lap = np.abs(cv2.Laplacian(lum, cv2.CV_32F, ksize=3))
    flat_dark = (lum < 0.25) & (grad < 0.08)
    grain = float(lap[flat_dark].mean()) if flat_dark.any() else 0.0
    hist = np.histogram(lum, bins=64, range=(0, 1))[0]
    levels = int((hist > lum.size * 0.0005).sum())
    smooth = grad < 0.04
    q = (lum * 255).astype(np.int16)
    step = (np.abs(np.diff(q, axis=1)) == 1) & smooth[:, 1:]
    band = float(step.mean())
    hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV).astype(np.float32)
    lit = hsv[:, :, 2] > 40
    sat = float(hsv[:, :, 1][lit].mean() / 255) if lit.any() else 0.0
    hue = hsv[:, :, 0][lit & (hsv[:, :, 1] > 50)] * 2 * np.pi / 180
    huesd = float(np.sqrt(-2 * np.log(max(1e-6, np.hypot(np.cos(hue).mean(), np.sin(hue).mean()))))) if hue.size else 0.0
    H, W = lum.shape
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.hypot((xx - W / 2) / (W / 2), (yy - H / 2) / (H / 2))
    vign = float(lum[r > 0.85].mean() / max(1e-3, lum[r < 0.4].mean()))
    sharp = cv2.blur(lap, (25, 25))
    dof = float(sharp.std() / max(1e-4, sharp.mean()))
    return dict(hard=hard, halo=halo, grain=grain, levels=levels, band=band, sat=sat, huesd=huesd, vign=vign, dof=dof)


if __name__ == "__main__":
    keys = ["hard", "halo", "grain", "levels", "band", "sat", "huesd", "vign", "dof"]
    print("%-28s" % "image" + "".join("%9s" % k for k in keys))
    for arg in sys.argv[1:]:
        label, path = arg.split("=", 1) if "=" in arg else (arg, arg)
        m = metrics(path)
        print("%-28s" % label[:28] + "".join(("%9d" if k == "levels" else "%9.3f") % m[k] for k in keys))
