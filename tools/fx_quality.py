"""Quality metrics for an 8x8 effect flipbook against its reference (2026-10-28).
Written after the user said our 1:1 copies "aren't the same quality": coverage/brightness ratios matched while the look
did not. These metrics target what actually differed (see Roblox Dev/Research/VFX and Animation/Effect Quality.md):

  ssim        structural similarity of luminance per frame (same frame index), only over the union of both lit areas
  detail      mean |Laplacian| inside the lit area - painted texture and inner shading vs smooth airbrushed fills
  core        correlation of distance-from-edge with brightness inside shapes - hot hearts, cooler edges (temperature look)
  colhist     overlap of the 2D (hue, value) histogram of lit pixels, 0..1 - the colour ramp actually used
  vspread     spread of luminance inside the lit area (90th - 10th percentile) - internal shading vs flat fills
  heat        correlation of brightness with "warmth" (hue toward yellow/white) inside the lit area - a gradient-mapped
              temperature look gives a strong positive value; one flat colour per blob gives ~0
  blobs       connected components of the lit mask - one merged mass vs a necklace of separate balls
  rough       silhouette roughness: perimeter^2 / (4 pi area) of the lit mask - cauliflower edges vs smooth discs
  soft        edge softness: share of the alpha edge band that is partial (0.1..0.9) - feathered vs cut-out edges
  lr          share of lit mass in the outer thirds (left+right) vs the middle - composition
  motion      mean absolute change between consecutive frames (curve) - speed/easing; holds = frames with ~no change

    python -I tools/fx_quality.py <ref.png> <ours.png> [grid=8]      prints per-metric means, ratios and curve correlations
Higher ssim/colhist are better (1 = identical). For the others the target is the reference's value (ratio 1.0).
"""
import sys
import cv2
import numpy as np


def frames(path, grid):
    im = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if im.shape[2] == 3:
        im = np.dstack([im, np.full(im.shape[:2], 255, np.uint8)])
    c = im.shape[1] // grid
    return [im[(i // grid) * c:(i // grid + 1) * c, (i % grid) * c:(i % grid + 1) * c].astype(np.float32) / 255 for i in range(grid * grid)]


def composite(f):
    a = f[:, :, 3:4]
    return f[:, :, :3] * a + 0.11 * (1 - a), f[:, :, 3]


def ssim(x, y, mask=None):
    """mean SSIM; with a mask only over the (dilated) union of both lit areas, so empty background cannot inflate it"""
    C1, C2 = 0.01 ** 2, 0.03 ** 2
    mx, my = cv2.GaussianBlur(x, (0, 0), 1.5), cv2.GaussianBlur(y, (0, 0), 1.5)
    sxx = cv2.GaussianBlur(x * x, (0, 0), 1.5) - mx * mx
    syy = cv2.GaussianBlur(y * y, (0, 0), 1.5) - my * my
    sxy = cv2.GaussianBlur(x * y, (0, 0), 1.5) - mx * my
    m = ((2 * mx * my + C1) * (2 * sxy + C2)) / ((mx * mx + my * my + C1) * (sxx + syy + C2))
    if mask is not None and mask.sum() > 20:
        return float(m[mask].mean())
    return float(m.mean())


def stats(f):
    rgb, a = composite(f)
    bgr8 = (np.clip(rgb, 0, 1) * 255).astype(np.uint8)
    hsv = cv2.cvtColor(bgr8, cv2.COLOR_BGR2HSV).astype(np.float32)
    lum = (rgb * np.float32([0.11, 0.59, 0.3])).sum(2).astype(np.float32)  # BGR order
    lit = (a > 0.2) & (lum > 0.08)
    out = {"lum": lum, "hsv": hsv, "lit": lit, "a": a}
    n = int(lit.sum())
    if n < 20:
        out.update(vspread=np.nan, heat=np.nan, blobs=np.nan, rough=np.nan, soft=np.nan, lr=np.nan, detail=np.nan, core=np.nan)
        return out
    L = lum[lit]
    out["vspread"] = float(np.percentile(L, 90) - np.percentile(L, 10))
    lap = cv2.Laplacian(lum, cv2.CV_32F, ksize=3)
    out["detail"] = float(np.abs(lap[cv2.erode(lit.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0]).mean()) if lit.sum() > 60 else np.nan  # painted texture inside shapes
    # warmth: hue distance from red toward yellow (OpenCV hue 0..180; red=0/180, yellow=30, cyan=90) plus whiteness
    h = hsv[:, :, 0][lit]; s = hsv[:, :, 1][lit] / 255
    hue_dist = np.minimum(h, 180 - h)  # 0 at red, 30 at yellow, 90 at cyan
    warmth = np.clip(hue_dist / 30, 0, 3) + (1 - s)
    out["heat"] = float(np.corrcoef(L, warmth)[0, 1]) if L.std() > 1e-4 and warmth.std() > 1e-4 else 0.0
    m8 = lit.astype(np.uint8)
    # core gradient: inside the shapes, does brightness rise from the edge toward the heart? (painted, temperature-mapped
    # fire: strongly yes; flat-filled blobs with a glow: weakly). Correlation of distance-to-edge with luminance.
    dist = cv2.distanceTransform(m8, cv2.DIST_L2, 3)[lit]
    out["core"] = float(np.corrcoef(dist, L)[0, 1]) if dist.std() > 1e-4 and L.std() > 1e-4 else np.nan
    nlab, lab, st, _ = cv2.connectedComponentsWithStats(m8, 8)
    big = (st[1:, cv2.CC_STAT_AREA] >= max(12, 0.01 * n)).sum()
    out["blobs"] = float(big)
    cnts, _ = cv2.findContours(m8, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    per = sum(cv2.arcLength(c, True) for c in cnts)
    out["rough"] = float(per * per / (4 * np.pi * n))
    edge = cv2.dilate(m8, np.ones((5, 5), np.uint8)) - cv2.erode(m8, np.ones((5, 5), np.uint8))
    ea = a[edge > 0]
    out["soft"] = float(((ea > 0.1) & (ea < 0.9)).mean()) if ea.size else np.nan
    w = lit.shape[1]; cols = lit.sum(0).astype(np.float32)
    out["lr"] = float((cols[: w // 3].sum() + cols[2 * w // 3:].sum()) / max(cols.sum(), 1))
    return out


def colhist(sa, sb):
    def h(s):
        if s["lit"].sum() < 20:
            return None
        hv = s["hsv"][s["lit"]]
        H, _, _ = np.histogram2d(hv[:, 0], hv[:, 2], bins=[18, 8], range=[[0, 180], [0, 256]])
        return H / H.sum()
    a, b = h(sa), h(sb)
    if a is None or b is None:
        return np.nan
    return float(np.minimum(a, b).sum())


def main():
    ref, ours = sys.argv[1], sys.argv[2]
    grid = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    FR, FO = frames(ref, grid), frames(ours, grid)
    rows = {k: ([], []) for k in ("core", "vspread", "heat", "detail", "blobs", "rough", "soft", "lr")}
    ss, ch, mo_r, mo_o = [], [], [], []
    prev_r = prev_o = None
    for fr, fo in zip(FR, FO):
        sr, so = stats(fr), stats(fo)
        active = sr["lit"].sum() >= 20 or so["lit"].sum() >= 20
        if active:
            union = cv2.dilate((sr["lit"] | so["lit"]).astype(np.uint8), np.ones((9, 9), np.uint8)) > 0
            ss.append(ssim(sr["lum"], so["lum"], union))
            ch.append(colhist(sr, so))
            for k in rows:
                rows[k][0].append(sr[k]); rows[k][1].append(so[k])
        lr_, lo_ = composite(fr)[0], composite(fo)[0]
        if prev_r is not None:
            mo_r.append(float(np.abs(lr_ - prev_r).mean())); mo_o.append(float(np.abs(lo_ - prev_o).mean()))
        prev_r, prev_o = lr_, lo_
    print("structural similarity (luma SSIM over the lit area, active frames): %.3f   colour-ramp overlap: %.3f" % (np.nanmean(ss), np.nanmean(ch)))
    print("%-8s %9s %9s %7s %7s" % ("metric", "ref", "ours", "ratio", "corr"))
    for k, (a, b) in rows.items():
        a, b = np.array(a, float), np.array(b, float)
        ok = ~np.isnan(a) & ~np.isnan(b)
        ma, mb = np.nanmean(a), np.nanmean(b)
        cor = np.corrcoef(a[ok], b[ok])[0, 1] if ok.sum() > 3 and a[ok].std() > 1e-6 and b[ok].std() > 1e-6 else np.nan
        print("%-8s %9.3f %9.3f %7.2f %7.2f" % (k, ma, mb, mb / ma if ma else np.nan, cor))
    mr, mo = np.array(mo_r), np.array(mo_o)
    holds_r = int((mr < 0.0015).sum()); holds_o = int((mo < 0.0015).sum())
    print("%-8s %9.4f %9.4f %7.2f %7.2f   (holds: ref %d, ours %d)" % ("motion", mr.mean(), mo.mean(), mo.mean() / mr.mean(), np.corrcoef(mr, mo)[0, 1], holds_r, holds_o))


if __name__ == "__main__":
    main()
