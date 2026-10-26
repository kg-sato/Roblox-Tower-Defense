"""Image measurements for the VFX stills, so frames can be checked without a person looking at them. Pillow only.

    python VFX/verify_stills.py sharp <region x0,y0,x1,y1> <image> [<image> ...]   sharpness per image
    python VFX/verify_stills.py lum <image> [<image> ...]                           mean luminance per image (0..1)
Sharpness = variance of Pillow's FIND_EDGES filter over the grayscale region (higher = sharper). Compare images ONLY when
the region shows the same kind of content (here: grass texture). Luminance = mean of the grayscale image / 255.
Used by VFX/verify_report.py. Limits: one still is one instant; this cannot see motion, only what a frame contains.
"""
import sys
from PIL import Image, ImageFilter, ImageStat


def sharpness(path, region):
    im = Image.open(path).convert("L").crop(region)
    return ImageStat.Stat(im.filter(ImageFilter.FIND_EDGES)).var[0]


def luminance(path):
    return ImageStat.Stat(Image.open(path).convert("L")).mean[0] / 255.0


if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "sharp":
        region = tuple(int(v) for v in sys.argv[2].split(","))
        for p in sys.argv[3:]:
            print("%9.1f  %s" % (sharpness(p, region), p))
    elif mode == "lum":
        for p in sys.argv[2:]:
            print("%.3f  %s" % (luminance(p), p))
