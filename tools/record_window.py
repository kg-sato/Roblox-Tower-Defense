"""Record a window (default: Roblox Studio) to an .mp4 so motion can be reviewed frame by frame.
No ffmpeg needed. Run with the Hunyuan3D venv in isolated mode:
   Hunyuan3D/.venv/Scripts/python.exe -I tools/record_window.py <out.mp4> <seconds> [fps=30] [title_contains="Roblox Studio"]
Then make contact sheets: tools/video_sheets.py <out.mp4> <dir> 0.1
Notes: uses PrintWindow, so the window can be behind others but not minimised (add --screen to grab the screen
area instead, which needs the window in front). Real rate is about 20 fps for a 1080p Studio window. Prints the real
captured fps, because screen grabbing can fall below the target on a busy PC; the file is written at that real rate
so playback speed is correct. Frames are held as JPEG in memory (about 0.3 MB each) until the clip ends. Local only: nothing is uploaded."""
import sys, time, ctypes
from ctypes import wintypes
import cv2, numpy as np
from PIL import ImageGrab

out = sys.argv[1]
seconds = float(sys.argv[2])
fps = float(sys.argv[3]) if len(sys.argv) > 3 else 30.0
needle = sys.argv[4] if len(sys.argv) > 4 else "Roblox Studio"

user32 = ctypes.windll.user32
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)  # real pixel coordinates on scaled displays
except Exception:
    pass

found = []
@ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
def enum(hwnd, _):
    if user32.IsWindowVisible(hwnd):
        n = user32.GetWindowTextLengthW(hwnd)
        if n:
            buf = ctypes.create_unicode_buffer(n + 1)
            user32.GetWindowTextW(hwnd, buf, n + 1)
            if needle.lower() in buf.value.lower():
                found.append((hwnd, buf.value))
    return True
user32.EnumWindows(enum, 0)
if not found:
    sys.exit(f"no visible window title contains {needle!r}")
hwnd, title = found[0]
rect = wintypes.RECT()
user32.GetWindowRect(hwnd, ctypes.byref(rect))
box = (rect.left, rect.top, rect.right, rect.bottom)
w, h = (box[2] - box[0]) // 2 * 2, (box[3] - box[1]) // 2 * 2
print(f"recording {title!r} at {box} for {seconds}s, target {fps} fps")

# Capture the window itself with PrintWindow(PW_RENDERFULLCONTENT) so other windows on top don't end up in the video.
gdi32 = ctypes.windll.gdi32
class BMI(ctypes.Structure):
    _fields_ = [("biSize", wintypes.DWORD), ("biWidth", wintypes.LONG), ("biHeight", wintypes.LONG), ("biPlanes", wintypes.WORD),
                ("biBitCount", wintypes.WORD), ("biCompression", wintypes.DWORD), ("biSizeImage", wintypes.DWORD),
                ("biXPelsPerMeter", wintypes.LONG), ("biYPelsPerMeter", wintypes.LONG), ("biClrUsed", wintypes.DWORD), ("biClrImportant", wintypes.DWORD)]
hdc_win = user32.GetWindowDC(hwnd)
hdc_mem = gdi32.CreateCompatibleDC(hdc_win)
bmp = gdi32.CreateCompatibleBitmap(hdc_win, w, h)
gdi32.SelectObject(hdc_mem, bmp)
bmi = BMI(); bmi.biSize = ctypes.sizeof(BMI); bmi.biWidth = w; bmi.biHeight = -h; bmi.biPlanes = 1; bmi.biBitCount = 32
buf = (ctypes.c_ubyte * (w * h * 4))()
use_print = "--screen" not in sys.argv
def grab():
    if use_print and user32.PrintWindow(hwnd, hdc_mem, 2):
        gdi32.GetDIBits(hdc_mem, bmp, 0, h, buf, ctypes.byref(bmi), 0)
        return np.frombuffer(buf, np.uint8).reshape(h, w, 4)[:, :, :3].copy()
    img = ImageGrab.grab(bbox=box, all_screens=True)  # fallback: screen area (needs the window in front)
    return cv2.cvtColor(np.asarray(img)[:h, :w], cv2.COLOR_RGB2BGR)

frames, stamps = [], []
t0 = time.perf_counter()
nxt = t0
while time.perf_counter() - t0 < seconds:
    # keep JPEG bytes, not raw frames: a raw 1080p frame is 6 MB, so a 30 s clip needed several GB of RAM
    frames.append(cv2.imencode('.jpg', grab(), [cv2.IMWRITE_JPEG_QUALITY, 93])[1])
    stamps.append(time.perf_counter() - t0)
    nxt += 1.0 / fps
    delay = nxt - time.perf_counter()
    if delay > 0:
        time.sleep(delay)
real = (len(frames) - 1) / (stamps[-1] - stamps[0]) if len(frames) > 1 else fps
vw = cv2.VideoWriter(out, cv2.VideoWriter_fourcc(*"mp4v"), real, (w, h))
for f in frames:
    vw.write(cv2.imdecode(f, cv2.IMREAD_COLOR))
vw.release()
gdi32.DeleteObject(bmp); gdi32.DeleteDC(hdc_mem); user32.ReleaseDC(hwnd, hdc_win)
gaps = np.diff(stamps) if len(stamps) > 1 else np.array([0])
print(f"wrote {out}: {len(frames)} frames, real {real:.1f} fps, worst frame gap {gaps.max()*1000:.0f} ms")
