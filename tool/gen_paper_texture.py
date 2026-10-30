"""生成一张 256×256 的可平铺纸纹（assets/textures/paper.png）。

原型用的是 SVG feTurbulence 噪点；这里换成一张更可控、体积更小的位图：
高亮度底 + 细颗粒 + 少量纤维，叠加在纸色上时在 7% 不透明度下只增加质感。

用法：python tool/gen_paper_texture.py
"""

from __future__ import annotations

import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SIZE = 256
BASE = 236.0          # 底亮度，接近纸色 #F6EFE6
GRAIN_SIGMA = 9.0     # 细颗粒强度
FIBER_COUNT = 90      # 纤维数量
SEED = 20261030

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "textures" / "paper.png"


def main() -> None:
    rng = np.random.default_rng(SEED)
    grain = rng.normal(0.0, GRAIN_SIGMA, (SIZE, SIZE))
    # 轻微的云状起伏：低分辨率噪声放大后与细颗粒相加
    coarse = rng.normal(0.0, 4.0, (8, 8))
    coarse = np.kron(coarse, np.ones((SIZE // 8, SIZE // 8)))
    canvas = np.clip(BASE + grain + coarse, 0, 255).astype(np.uint8)

    image = Image.fromarray(canvas, mode="L")

    # 手工纤维：短、弯、低对比
    draw = ImageDraw.Draw(image)
    random.seed(SEED)
    for _ in range(FIBER_COUNT):
        x = random.uniform(0, SIZE)
        y = random.uniform(0, SIZE)
        angle = random.uniform(0, math.pi)
        length = random.uniform(3, 12)
        bend = random.uniform(-1.2, 1.2)
        x2 = x + math.cos(angle) * length
        y2 = y + math.sin(angle) * length
        xm = (x + x2) / 2 + math.cos(angle + math.pi / 2) * bend
        ym = (y + y2) / 2 + math.sin(angle + math.pi / 2) * bend
        shade = int(BASE - random.uniform(18, 40))
        draw.line([(x, y), (xm, ym), (x2, y2)], fill=shade, width=1)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, format="PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.1f} KB, {SIZE}x{SIZE})")


if __name__ == "__main__":
    main()