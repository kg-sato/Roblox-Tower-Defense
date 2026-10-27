import ctypes,sys
from ctypes import wintypes
u=ctypes.windll.user32
f=[]
@ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
def cb(h,_):
    n=u.GetWindowTextLengthW(h)
    if n:
        b=ctypes.create_unicode_buffer(n+1); u.GetWindowTextW(h,b,n+1)
        if 'Roblox Studio' in b.value and u.IsWindowVisible(h): f.append(h)
    return True
u.EnumWindows(cb,0); u.ShowWindow(f[0], int(sys.argv[1])); print('ok')
