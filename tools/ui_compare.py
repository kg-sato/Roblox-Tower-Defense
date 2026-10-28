"""Capture a Roblox UI screen from Studio and compare it with a reference screenshot, 1:1.
  Hunyuan3D/.venv/Scripts/python.exe -I tools/ui_compare.py capture <out.png>
      grabs the Studio window, finds the four 6 px magenta (255,0,255) corner markers of the 16:9 "Stage" frame
      (built by the test harness, see the 1to1 notes) and saves the stage, resized to 1920x1080
  Hunyuan3D/.venv/Scripts/python.exe -I tools/ui_compare.py compare <ref.png> <ours.png> <out_prefix> [x0,y0,x1,y1 ...]
      writes <prefix>_side.jpg (ref | ours), <prefix>_blend.jpg (50/50), <prefix>_edges.jpg (ref edges red, ours green,
      overlap yellow) and prints: edge F1 (how well the outlines line up, 3 px tolerance), mean colour difference
      (Delta E, CIELAB) and per-region numbers for the optional boxes (reference pixels). Local only."""
import sys, ctypes
from ctypes import wintypes
import cv2, numpy as np


def grab_studio():
    user32 = ctypes.windll.user32
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
    except Exception:
        pass
    found = []
    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def enum(h, _):
        n = user32.GetWindowTextLengthW(h)
        if n and user32.IsWindowVisible(h):
            b = ctypes.create_unicode_buffer(n + 1); user32.GetWindowTextW(h, b, n + 1)
            if "Roblox Studio" in b.value: found.append(h)
        return True
    user32.EnumWindows(enum, 0)
    h = found[0]; r = wintypes.RECT(); user32.GetWindowRect(h, ctypes.byref(r))
    w, ht = r.right - r.left, r.bottom - r.top
    gdi = ctypes.windll.gdi32
    dc = user32.GetWindowDC(h); mem = gdi.CreateCompatibleDC(dc); bmp = gdi.CreateCompatibleBitmap(dc, w, ht); gdi.SelectObject(mem, bmp)
    user32.PrintWindow(h, mem, 2)
    buf = (ctypes.c_ubyte * (w * ht * 4))()
    class BMI(ctypes.Structure):
        _fields_ = [("a", wintypes.DWORD), ("w", wintypes.LONG), ("h", wintypes.LONG), ("p", wintypes.WORD), ("b", wintypes.WORD),
                    ("c", wintypes.DWORD), ("s", wintypes.DWORD), ("x", wintypes.LONG), ("y", wintypes.LONG), ("u", wintypes.DWORD), ("i", wintypes.DWORD)]
    bmi = BMI(); bmi.a = ctypes.sizeof(BMI); bmi.w = w; bmi.h = -ht; bmi.p = 1; bmi.b = 32
    gdi.GetDIBits(mem, bmp, 0, ht, buf, ctypes.byref(bmi), 0)
    img = np.frombuffer(buf, np.uint8).reshape(ht, w, 4)[:, :, :3].copy()
    gdi.DeleteObject(bmp); gdi.DeleteDC(mem); user32.ReleaseDC(h, dc)
    return img


def capture(out):
    img = grab_studio()
    b, g, r = img[..., 0].astype(int), img[..., 1].astype(int), img[..., 2].astype(int)
    m = (r > 230) & (b > 230) & (g < 40)
    ys, xs = np.where(m)
    if len(xs) < 16:
        sys.exit("markers not found: is the Stage with magenta corner markers on screen and Studio not minimised?")
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    crop = img[y0:y1, x0:x1]
    cv2.imwrite(out, cv2.resize(crop, (1920, 1080), interpolation=cv2.INTER_CUBIC))
    print(f"stage at x{x0}-{x1} y{y0}-{y1} ({x1 - x0}x{y1 - y0}) -> {out}")


def edges(img):
    g = cv2.GaussianBlur(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), (5, 5), 0)
    return cv2.Canny(g, 60, 140) > 0


def f1(ea, eb, tol=3):
    k = np.ones((2 * tol + 1, 2 * tol + 1), np.uint8)
    da, db = cv2.dilate(ea.astype(np.uint8), k) > 0, cv2.dilate(eb.astype(np.uint8), k) > 0
    p = (eb & da).sum() / max(eb.sum(), 1); r = (ea & db).sum() / max(ea.sum(), 1)
    return 2 * p * r / max(p + r, 1e-9), p, r


def delta_e(a, b):
    la, lb = cv2.cvtColor(a, cv2.COLOR_BGR2LAB).astype(np.float32), cv2.cvtColor(b, cv2.COLOR_BGR2LAB).astype(np.float32)
    la[..., 0] *= 100 / 255; lb[..., 0] *= 100 / 255; la[..., 1:] -= 128; lb[..., 1:] -= 128
    return np.linalg.norm(la - lb, axis=2)


def compare(ref_p, ours_p, prefix, boxes):
    ref = cv2.resize(cv2.imread(ref_p), (1920, 1080)); ours = cv2.resize(cv2.imread(ours_p), (1920, 1080))
    ea, eb = edges(ref), edges(ours)
    F, P, R = f1(ea, eb)
    dE = delta_e(ref, ours)
    print(f"whole screen: edge F1 {F:.3f} (precision {P:.3f}, recall {R:.3f}), mean Delta E {dE.mean():.1f}")
    for bx in boxes:
        x0, y0, x1, y1 = bx
        Fb, _, _ = f1(ea[y0:y1, x0:x1], eb[y0:y1, x0:x1])
        ma, mb = ref[y0:y1, x0:x1].reshape(-1, 3).mean(0), ours[y0:y1, x0:x1].reshape(-1, 3).mean(0)
        print(f"  box {bx}: edge F1 {Fb:.3f}, Delta E {dE[y0:y1, x0:x1].mean():.1f}, mean BGR ref {ma.astype(int)} ours {mb.astype(int)}")
    side = np.hstack([ref, ours]); cv2.imwrite(prefix + "_side.jpg", cv2.resize(side, (1920, 540)))
    cv2.imwrite(prefix + "_blend.jpg", cv2.resize(cv2.addWeighted(ref, 0.5, ours, 0.5, 0), (1280, 720)))
    ov = np.zeros_like(ref); ov[ea] = (0, 0, 255); ov[eb] = (0, 255, 0); ov[ea & eb] = (0, 255, 255)
    cv2.imwrite(prefix + "_edges.jpg", cv2.resize(ov, (1280, 720)))


if __name__ == "__main__":
    if sys.argv[1] == "capture":
        capture(sys.argv[2])
    else:
        boxes = [tuple(int(v) for v in a.split(",")) for a in sys.argv[5:]]
        compare(sys.argv[2], sys.argv[3], sys.argv[4], boxes)
