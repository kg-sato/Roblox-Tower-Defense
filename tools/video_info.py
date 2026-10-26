import cv2, glob, os, sys
folder = sys.argv[1]
for p in sorted(glob.glob(os.path.join(folder, "*.mp4"))):
    c = cv2.VideoCapture(p)
    n = c.get(cv2.CAP_PROP_FRAME_COUNT); f = c.get(cv2.CAP_PROP_FPS) or 0
    w = int(c.get(cv2.CAP_PROP_FRAME_WIDTH)); h = int(c.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"{os.path.basename(p)}: {w}x{h} {f:.1f}fps frames={int(n)} dur={n/f if f else 0:.1f}s")
    c.release()
