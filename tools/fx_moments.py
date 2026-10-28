"""Same-moment side-by-side frames from an fx_compare recording (left half = reference, right half = ours).
    python -I tools/fx_moments.py <frames.mp4> <out.png> [moments=0.05,0.15,0.3,0.45,0.65,0.85,1.1] [fps=30]
Finds the first burst (first lit frame after >= 10 dark frames) and cuts both halves at the same times after it, so the
two effects are compared at identical moments (they are emitted together). Top row = reference, bottom row = ours."""
import sys
import cv2
import numpy as np


def main():
    src, out = sys.argv[1], sys.argv[2]
    moms = [float(x) for x in sys.argv[3].split(",")] if len(sys.argv) > 3 else [0.05, 0.15, 0.3, 0.45, 0.65, 0.85, 1.1]
    fps = float(sys.argv[4]) if len(sys.argv) > 4 else 30.0
    cap = cv2.VideoCapture(src); fr = []
    while True:
        ok, f = cap.read()
        if not ok:
            break
        fr.append(f)
    w = fr[0].shape[1]
    lit = [(cv2.cvtColor(f, cv2.COLOR_BGR2GRAY) > 40).mean() for f in fr]
    start, dark = None, 0
    for i, v in enumerate(lit):
        if v < 0.002:
            dark += 1
        else:
            if dark >= 10:
                start = i
                break
            dark = 0
    if start is None:
        raise SystemExit("no burst found (need a dark gap before an emission)")
    cols = []
    for t in moms:
        i = min(len(fr) - 1, start + int(round(t * fps)))
        L, R = fr[i][:, : w // 2], fr[i][:, w // 2:]
        L = cv2.resize(L, (L.shape[1] // 2, L.shape[0] // 2)); R = cv2.resize(R, (R.shape[1] // 2, R.shape[0] // 2))
        cv2.putText(L, "t=%.2fs REF" % t, (6, 20), 0, 0.55, (140, 230, 255), 2)
        cv2.putText(R, "t=%.2fs OURS" % t, (6, 20), 0, 0.55, (140, 255, 160), 2)
        cols.append(np.vstack([L, R]))
    cv2.imwrite(out, np.hstack(cols))
    print("burst at frame", start, "->", out)


if __name__ == "__main__":
    main()
