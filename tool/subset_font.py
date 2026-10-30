"""生成中文衬线字体的子集。

用法：
    python tool/subset_font.py

前置：
    - 完整字体放在 build/fontsrc/NotoSerifSC-SemiBold.otf（不进仓库）
    - pip install fonttools

做法：
    把 lib/ 下所有 Dart 字符串里出现的汉字、标点、数字收成字形集，
    再用 pyftsubset 裁出 assets/fonts/NotoSerifSC-SemiBold.otf。

为什么是子集：完整 Noto Serif SC SemiBold 有 11.8MB，而 App 里用衬线的
只有标题、大数字这些固定文案（用户输入一律用无衬线正文），裁完通常
只剩一两百 KB。新增文案如果用了衬线却不在字形集里，会回落到系统字体，
所以改完标题文案后要重跑一次这个脚本。
"""

from __future__ import annotations

import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "build" / "fontsrc" / "NotoSerifSC-SemiBold.otf"
OUTPUT = ROOT / "assets" / "fonts" / "NotoSerifSC-SemiBold.otf"
GLYPHS = ROOT / "tool" / "glyphs.txt"

EXTRA = "·—…“”‘’《》「」、（）：；！？0123456789abcABC%+-,. "


def is_serial_candidate(ch: str) -> bool:
    code = ord(ch)
    return (
        0x4E00 <= code <= 0x9FFF  # 汉字
        or 0x3000 <= code <= 0x303F  # 中文标点
        or 0xFF00 <= code <= 0xFFEF  # 全角
        or 0x20 <= code < 0x7F  # ASCII
    )


def collect() -> str:
    chars: set[str] = set()
    for path in (ROOT / "lib").rglob("*.dart"):
        chars.update(filter(is_serial_candidate, path.read_text(encoding="utf-8")))
    chars.update(EXTRA)
    return "".join(sorted(chars))


def main() -> int:
    if not SOURCE.exists():
        print(f"缺少完整字体：{SOURCE}")
        return 1
    text = collect()
    GLYPHS.write_text(text, encoding="utf-8")
    subprocess.run(
        [
            sys.executable,
            "-m",
            "fontTools.subset",
            str(SOURCE),
            f"--text-file={GLYPHS}",
            f"--output-file={OUTPUT}",
            "--layout-features=",
            "--no-hinting",
            "--desubroutinize",
        ],
        check=True,
    )
    print(f"字形 {len(text)} 个，输出 {OUTPUT.stat().st_size / 1024:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())