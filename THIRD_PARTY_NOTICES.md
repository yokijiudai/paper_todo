# 第三方资源与许可

本项目自身代码使用 BSD 3-Clause，见仓库根目录 `LICENSE`。
下面列出的第三方资源各自遵循其原始许可证。

## 字体

### Noto Serif SC SemiBold

- 来源：<https://github.com/notofonts/noto-cjk>（`Serif/SubsetOTF/SC/NotoSerifSC-SemiBold.otf`）
- 文件：`assets/fonts/NotoSerifSC-SemiBold.otf`（约 163 KB）
- 版本：Version 2.003
- 版权：Copyright 2017-2024 Adobe (<http://www.adobe.com/>)
- 许可证：SIL Open Font License 1.1，全文见 [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt)
- 改动说明：原始字体约 11.2 MB，仓库内文件是用 `tool/subset_font.py`
  生成的**字形子集**（属 OFL 意义上的 Modified Version）——只保留 App 实际用到的
  字符（常用汉字、ASCII、中文标点、`·`、`–` 等），字形轮廓与 hmtx 未改动。
  原始文件名与内部字体名（Noto Serif SC SemiBold）保持不变，且未用 "Noto" /
  Reserved Font Name 为本项目背书。

### 回退字体

`lib/theme/app_theme.dart` 中 `fontFamily` 只指定了 Noto Serif SC，未分发任何
其他字体文件。英文与数字字形缺失时按系统回退，其中 Android 自带的字体
（Noto Sans 等）随系统分发，不随本仓库分发。

## 图标

- Material Icons（`Icons.*`，来自 Flutter SDK 的 `material_icons` 字体）
- 许可证：Apache License 2.0
- 说明：由 Flutter SDK / `uses-material-design: true` 打包，本仓库不存储该字体文件。

## 依赖包

`pubspec.yaml` 中的依赖（`shared_preferences` 等）均为 pub.dev 上的开源包，
各自许可证见其包内 `LICENSE` 文件，可用
`flutter pub deps` 或到 <https://pub.dev/packages> 查询。

## 设计素材

- `design/`：本项目自绘的原型（HTML / CSS），与代码同许可。
- `assets/textures/paper.png`：由 `tool/gen_paper_texture.py` 程序化生成，非第三方素材。
- `docs/screenshots/`：本项目截图，不含第三方版权内容。