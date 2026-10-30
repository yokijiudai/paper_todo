"""生成启动图标（传统 mipmap + Android 8 自适应图标 + 启动页 logo）。

设计：纸色底上斜放一张「纸条」，左上角一小段赭红胶带，纸面上用赭红（#A9542A）
画一个手绘感对勾——和 App 里的勾选圈、之后的新任务是同一种语言。
底是满色正方形，自适应图标的前景只占中间 66%，保证圆形 / 圆角方形裁切都完整。

用法：
    python tool/gen_app_icon.py        # 需要 Pillow

产出：
    android/app/src/main/res/mipmap-*/ic_launcher.png      传统图标（40/48/60/72/80... 见 SIZES）
    android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
    android/app/src/main/res/drawable/ic_launcher_foreground.xml  矢量前景
    android/app/src/main/res/values/ic_launcher_colors.xml        背景色
    android/app/src/main/res/drawable/launch_preview.xml          启动页居中 logo
    docs/branding/app-icon.png                                     仓库展示图
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BRANDING = ROOT / "docs" / "branding"

SUPER = 1024  # 所有形状都按 1024 画，最后再缩，避免小尺寸锯齿

BG = "#F6EFE6"       # 纸色
PAPER = "#FFF9F2"    # 纸条
INK = "#A9542A"      # 赭红：对勾、胶带
INK_DEEP = "#6F3218"
TAPE = "#D8B27B"     # 胶带

# 传统图标尺寸（mdpi 48 起的倍数）
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# 启动页 logo 尺寸
SPLASH = {"drawable-mdpi": 96, "drawable-hdpi": 144, "drawable-xhdpi": 192,
          "drawable-xxhdpi": 288, "drawable-xxxhdpi": 384}


def rotate(points, deg, center=(SUPER / 2, SUPER / 2)):
    rad = math.radians(deg)
    cos, sin = math.cos(rad), math.sin(rad)
    cx, cy = center
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * cos - dy * sin, cy + dx * sin + dy * cos))
    return out


def dilate(points, px):
    """把多边形沿质心方向外扩（阴影用）。"""
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        d = math.hypot(dx, dy) or 1
        out.append((x + dx / d * px, y + dy / d * px))
    return out


def draw_tile(paper_fill, paper_outline, check_color, tape=True, bg=BG):
    """画一张 1024 的图标：底 + 斜纸条 + 胶带 + 对勾。"""
    img = Image.new("RGBA", (SUPER, SUPER), bg)
    d = ImageDraw.Draw(img)

    # 纸条边缘和轮廓先放大 4 倍画、再缩回来，去掉 PIL 多边形的锯齿
    scale = 4
    big = Image.new("RGBA", (SUPER * scale, SUPER * scale), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)

    def poly(points, **kw):
        bd.polygon([(x * scale, y * scale) for x, y in points], **kw)

    sheet = [(300, 236), (716, 200), (752, 776), (330, 812)]
    sheet = rotate(sheet, 7)

    # 纸条投影：向下、向右各偏一点，只在右侧和底部露出
    def shadow(dy, dx, alpha):
        shifted = rotate([(300 + dx, 236 + dy), (716 + dx, 200 + dy),
                          (752 + dx, 776 + dy), (330 + dx, 812 + dy)], 7)
        poly(shifted, fill=(120, 72, 30, alpha))

    shadow(14, 12, 30)
    shadow(8, 7, 34)
    # 纸条
    poly(sheet, fill=paper_fill, outline=paper_outline, width=6 * scale if paper_outline else 0)

    # 胶带：贴在纸条左上角，半透明沙色
    t = rotate([(274, 232), (472, 206), (478, 292), (280, 318)], 7)
    poly(t, fill=TAPE + "CC", outline=TAPE)

    down = big.resize((SUPER, SUPER), Image.LANCZOS)
    img.alpha_composite(down)

    # 横线：先按 4 倍画再缩，边缘才不会毛毛的
    lines = [((392, 372), (660, 350)), ((388, 462), (680, 440)), ((384, 552), (548, 534))]
    lbig = Image.new("RGBA", (SUPER * scale, SUPER * scale), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lbig)
    for (x1, y1), (x2, y2) in lines:
        a = rotate([(x1, y1)], 7)[0]
        b = rotate([(x2, y2)], 7)[0]
        ld.line([(a[0] * scale, a[1] * scale), (b[0] * scale, b[1] * scale)],
                fill=INK + "4D", width=16 * scale)
    img.alpha_composite(lbig.resize((SUPER, SUPER), Image.LANCZOS))

    # 对勾：两笔，圆头，稍微手绘
    p1 = rotate([(386, 636)], 7)[0]
    p2 = rotate([(486, 704)], 7)[0]
    p3 = rotate([(664, 508)], 7)[0]
    d.line([p1, p2], fill=check_color, width=64, joint="curve")
    d.line([p2, p3], fill=check_color, width=64, joint="curve")
    for p in (p2, p3):
        d.ellipse([p[0] - 32, p[1] - 32, p[0] + 32, p[1] + 32], fill=check_color)
    return img


def maskable(img):
    """自适应图标前景：100dp 图层里，官方安全区是直径 66dp 的圆。

    先把整张 1024 画布的「内容外框」缩到 66dp 圆的 ~78%（约 54dp），再居中——
    这样圆形 / 圆角方形 / 水滴形等各种裁切下，纸条四角都在安全区内。
    """
    bbox = img.getbbox()
    content = img.crop(bbox)
    target = int(SUPER * 0.66 * 0.78)
    ratio = min(target / content.width, target / content.height)
    content = content.resize((max(1, int(content.width * ratio)), max(1, int(content.height * ratio))),
                             Image.LANCZOS)
    canvas = Image.new("RGBA", (SUPER, SUPER), (0, 0, 0, 0))
    off = ((SUPER - content.width) // 2, (SUPER - content.height) // 2)
    canvas.alpha_composite(content, off)
    return canvas


def write_png(img, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, format="PNG", optimize=True)
    return path.stat().st_size


def main() -> None:
    legacy = draw_tile(PAPER, None, INK)
    fg_full = draw_tile(PAPER, None, INK, bg=(0, 0, 0, 0))
    fg = maskable(fg_full)
    # 自适应图层常规只显示中间 72dp（1024 画布上的 0.768～0.768+0.682），
    # 让启动页 logo 与桌面图标看起来一样大
    splash_logo = fg_full.crop((int(SUPER * 0.768), int(SUPER * 0.768),
                                int(SUPER * 0.768) + int(SUPER * 0.682),
                                int(SUPER * 0.768) + int(SUPER * 0.682)))

    total = 0
    for folder, size in SIZES.items():
        total += write_png(legacy, RES / folder / "ic_launcher.png", size)
        print(f"  {folder}/ic_launcher.png {size}x{size}")

    # 自适应图标前景（432dp 画布 → 各密度位图）
    fg_sizes = {"mipmap-mdpi": 108, "mipmap-hdpi": 162, "mipmap-xhdpi": 216,
                "mipmap-xxhdpi": 324, "mipmap-xxxhdpi": 432}
    for folder, size in fg_sizes.items():
        total += write_png(fg, RES / folder / "ic_launcher_foreground.png", size)

    # 启动页 logo（透明底，居中；尺寸取 72dp 图层）
    for folder, size in SPLASH.items():
        total += write_png(splash_logo, RES / folder / "launch_logo.png", size)

    BRANDING.mkdir(parents=True, exist_ok=True)
    legacy.resize((512, 512), Image.LANCZOS).save(BRANDING / "app-icon.png", format="PNG", optimize=True)
    write_png(fg, BRANDING / "app-icon-foreground.png", 432)
    print(f"wrote icons, {total / 1024:.0f} KB total")


if __name__ == "__main__":
    main()