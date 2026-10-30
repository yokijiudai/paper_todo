"""把 build/preview 里的真机截图压成 README 用的缩略图。

用法：
    python tool/make_readme_shots.py

原图 1080×2400 每张三四百 KB，直接进仓库太重；按宽度 600 缩放后
每张 ~60 KB，读起来还清楚。
"""

from __future__ import annotations

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "build" / "preview"
TARGET = ROOT / "docs" / "screenshots"
WIDTH = 600

SHOTS = {
    # 展示用
    "release-home.png": "home.jpg",
    "release-stats.png": "stats.jpg",
    "release-week-sheet.png": "week-sheet.jpg",
    "release-form.png": "form.jpg",
    "form-edit.png": "form-edit.jpg",
    "delete-dialog.png": "delete-dialog.jpg",
    # 验收用：冷启动、字号 1.3 倍
    "cold2.png": "acceptance-cold-start.jpg",
    "scale-1.3.png": "acceptance-scale-home.jpg",
    "scale-1.3-stats.png": "acceptance-scale-stats.jpg",
    "scale-1.3-form.png": "acceptance-scale-form.jpg",
}


def main() -> int:
    TARGET.mkdir(parents=True, exist_ok=True)
    for src, dst in SHOTS.items():
        path = SOURCE / src
        if not path.exists():
            print(f"跳过（不存在）：{src}")
            continue
        image = Image.open(path).convert("RGB")
        scale = WIDTH / image.width
        image = image.resize((WIDTH, round(image.height * scale)), Image.LANCZOS)
        out = TARGET / dst
        image.save(out, quality=82, optimize=True)
        print(f"{dst}: {out.stat().st_size / 1024:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())