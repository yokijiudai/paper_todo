# 项目文件结构设计 · 温暖手作待办

> 依据：`` 里的四屏高保真原型（home / add / detail / stats）与 `tokens.css`。
> 目标：把原型落成一套能长期改的 Flutter 结构 —— 视觉变量集中、数据只有一条通路、页面只做布局。

---

## 1. 约束与前提

| 项 | 现状 |
|---|---|
| 平台 | 只有 `../android`，没有 ios / web / windows |
| SDK | Flutter 3.47.8 / Dart 3.13.7（`../pubspec.yaml` 写 `^3.13.7`） |
| 设计基准 | 原型按 390×844 画；CSS px 1:1 用逻辑像素，不做缩放 |
| 主题 | 仅浅色（纸感暖色），不实现深色模式 |
| 状态管理 | 不引入 provider/riverpod：`ChangeNotifier` + `InheritedNotifier` |
| 现有代码 | `../lib/main.dart` 是旧的蓝色 Material 版（688 行，含假数据与 TODO），落地时整体替换 |

---

## 2. 目录总览

```
node/
├─ android/                        Android 原生工程（不改）
├─ assets/
│  ├─ fonts/
│  │  └─ NotoSerifSC-SemiBold.otf  标题衬线（w600）
│  ├─ textures/
│  │  └─ paper.png                 512×512 无缝纸纹，整屏叠加
│  └─ art/                         预留：将来换插画再放 SVG（当前首屏插画用代码画）
├─ design/                         原型，只作规范参考，不参与打包
│  ├─ tokens.css  app.css
│  └─ home.html  add.html  detail.html  stats.html
├─ lib/
│  ├─ main.dart                    runApp + MaterialApp + 路由 + 注入 controller
│  ├─ theme/
│  │  ├─ tokens.dart               颜色 / 字号 / 间距 / 圆角 / 阴影 / 动效常量
│  │  └─ app_theme.dart            ThemeData、TextTheme、CardTheme、系统栏样式
│  ├─ models/
│  │  └─ todo_note.dart            TodoNote + TodoCategory + toJson/fromJson
│  ├─ data/
│  │  ├─ todo_store.dart           TodoStore 接口 + SharedPreferences 实现 + 内存实现
│  │  └─ seed_data.dart            首次启动的示例数据
│  ├─ state/
│  │  └─ todo_controller.dart      TodoController + TodoScope（InheritedNotifier）
│  ├─ utils/
│  │  └─ formatters.dart           日期 / 周次 / 中文数字 / 时间标签格式化
│  ├─ screens/
│  │  ├─ root_shell.dart           IndexedStack + DiyTabBar（今天 / 新建 / 回顾）
│  │  ├─ home_page.dart            今天：标题、进度、未完成、今天已完成
│  │  ├─ note_form_page.dart       新建与编辑同一页，传 note 即编辑
│  │  └─ stats_page.dart           回顾：统计卡、柱状图、某天明细、换一周
│  └─ widgets/
│     ├─ paper_scaffold.dart       纸纹背景 + 暖色系统栏 + PaperCard
│     ├─ note_tile.dart            待办行（原型 .todo）
│     ├─ check_circle.dart         手绘勾选圈（自定义画布 + 动画）
│     ├─ category_chip.dart        分类小标签（原型 .chip）
│     ├─ diy_tabbar.dart           三格 + 中间凸起 + 的自定义标签栏
│     ├─ hero_notes_art.dart       首屏叠纸插画（CustomPainter）
│     ├─ day_bar_chart.dart        周柱状图（CustomPainter + 点选）
│     └─ week_sheet.dart           月历弹层（按周选、年月选择器）
└─ test/
   ├─ models/todo_note_test.dart
   ├─ state/todo_controller_test.dart
   └─ widget/home_page_test.dart
```

**相对你给的草稿，加了 5 个文件**（都有明确理由，见 §4）：

- `screens/root_shell.dart`：标签栏只建一次，`IndexedStack` 保住「回顾」页选中的那一周；否则两个页面各建一条 tabbar，切页丢状态。
- `widgets/note_tile.dart`：待办行在首页出现两次（未完成 / 已完成），统计页的「某天明细」复用同一套排版；不抽出来就要复制三份。
- `widgets/hero_notes_art.dart`：首屏插画用 `CustomPainter` 画，省掉 `flutter_svg` 依赖（见 §10）。
- `utils/formatters.dart`：`10 月 30 日 · 周五`、`十月 · 第四周`、`五件事`、`10.23 – 10.29` 这些文案在 4 个文件里都要用。
- `data/seed_data.dart`：示例数据从 `main.dart` 里挪出来，也方便测试。

---

## 3. 分层与依赖方向

```
main.dart ──► screens ──► widgets ──► theme / utils / models
                  │
                  └──► state ──► data ──► models
```

硬规则：

1. `theme/`、`models/` 不依赖 Flutter 之外的任何项目文件；`models` 只用 `dart:core`（最多 `package:flutter/foundation.dart` 的 `@immutable`）。
2. `widgets/` 不 import `screens/`，不直接读写存储；一切数据通过构造参数传入。
3. `screens/` 不直接碰 `data/`；只通过 `TodoScope.of(context)` 调 controller。
4. 只有 `main.dart` 知道「用哪个 Store 实现」，换存储只改一处。

---

## 4. 逐文件设计

### 4.1 `theme/tokens.dart`

从 `tokens.css` 逐条搬过来，命名保持可对照（CSS 变量名 → 驼峰）。全部 `static const`，不建实例。

```dart
abstract final class AppColors {
  static const bg          = Color(0xFFF6EFE6);
  static const surface     = Color(0xFFFFF9F2);
  static const surface2    = Color(0xFFF1E6D8);
  static const text        = Color(0xFF2B1D14);
  static const muted       = Color(0xFF6E5A4B);
  static const line        = Color(0xFFE7D9C8);
  static const primary     = Color(0xFFA9542A);
  static const primaryInk  = Color(0xFFFFFFFF);
  static const primarySoft = Color(0xFFF2E1D4);
  static const primaryDeep = Color(0xFF6F3218);
  static const accent      = Color(0xFF5E7A4A);
  static const accentSoft  = Color(0xFFE5EBDC);
  static const link        = Color(0xFF52703F);
  static const sand        = Color(0xFFE9CFA9);
  static const sandDeep    = Color(0xFFD8B27B);
  static const sandSoft    = Color(0xFFF0E2CE);
  static const danger      = Color(0xFF8C3B24);
}

abstract final class AppSpace   { static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0,
                                 s5 = 24.0, s6 = 32.0, s7 = 48.0, s8 = 64.0; }
abstract final class AppRadius  { static const sm = 10.0, md = 16.0, lg = 24.0, full = 999.0; }
abstract final class AppSize    { static const pageX = 20.0, tap = 44.0, tabBar = 49.0; }
abstract final class AppText    { static const xs = 12.0, sm = 14.0, md = 16.0,
                                 lg = 20.0, xl = 24.0, xxl = 32.0, xxxl = 40.0; }
abstract final class AppShadows {
  static const sm   = [BoxShadow(color: Color(0x14784820), blurRadius: 8,  offset: Offset(0, 2))];
  static const md   = [BoxShadow(color: Color(0x1F784820), blurRadius: 24, offset: Offset(0, 8))];
  static const lift = [BoxShadow(color: Color(0x29784820), blurRadius: 28, offset: Offset(0, 10))];
}
abstract final class AppMotion  { static const fast = Duration(milliseconds: 160);
                                 static const base = Duration(milliseconds: 200);
                                 static const ease = Cubic(0.2, 0.8, 0.2, 1); }
```

> 透明度：CSS 的 `rgba(120,72,30,.08)` → `Color(0x14784820)`（`.08×255≈20=0x14`），不要用已废弃的 `withOpacity`。

### 4.2 `theme/app_theme.dart`

一个 `AppTheme.light` 静态 getter，集中收口：

- `ColorScheme.light(primary: primary, onPrimary: primaryInk, surface: surface, onSurface: text, error: danger, outline: line)`
- `TextTheme`：`displayLarge` 32/1.25 衬线 w600、`headlineSmall` 24/1.35 衬线 w600、`titleMedium` 16 w600、`bodyLarge` 16/1.6、`bodyMedium` 14、`bodySmall` 12 muted、`labelSmall` 11 w600 字距 0.4。
- `cardTheme: CardThemeData(color: surface, elevation: 0, margin: EdgeInsets.zero, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)))`
- `scaffoldBackgroundColor: AppColors.bg`、`splashFactory: InkSparkle.splashFactory`（点在纸上的感觉）。
- `SystemUiOverlayStyle`：透明状态栏 + 深色图标 + 底部导航栏 `surface` 底、深色图标；`MainActivity` 已是 edge-to-edge，靠 `SafeArea` 让位。

### 4.3 `models/todo_note.dart`

```dart
enum TodoCategory {
  work('工作'), life('生活'), study('学习'), idea('灵感');
  const TodoCategory(this.label);
  final String label;
  static TodoCategory fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => work);
}

@immutable
class TodoNote {
  const TodoNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category = TodoCategory.work,
    this.timeLabel,
    this.completedAt,
  });

  final String id;
  final String content;
  final TodoCategory category;
  final String? timeLabel;     // "14:00" / "傍晚" / "睡前"，纯展示
  final DateTime createdAt;
  final DateTime? completedAt; // null = 未完成

  bool get isCompleted => completedAt != null;

  TodoNote copyWith({String? content, TodoCategory? category, String? timeLabel,
                     DateTime? completedAt, bool clearCompletedAt = false});
  Map<String, Object?> toJson();
  factory TodoNote.fromJson(Map<String, Object?> json);
}
```

要点：

- **完成状态只存 `completedAt`**，`isCompleted` 是派生 getter；取消完成 → `completedAt: null`（`copyWith` 用 `clearCompletedAt` 表达「显式置空」，避免 `null` 与「不修改」混淆）。
- `toJson` 时间统一 `toIso8601String()`；`fromJson` 用 `DateTime.tryParse` 兜底 `createdAt`（坏数据不能让整份列表读不出来）。
- 不做 `==` 重载（列表按 id 改），省掉 hashCode 维护。

### 4.4 `data/todo_store.dart`

```dart
abstract interface class TodoStore {
  Future<List<TodoNote>> load();
  Future<void> save(List<TodoNote> notes);
}

/// 存进 SharedPreferences：一个 key 放整段 JSON
class SharedPrefsTodoStore implements TodoStore {
  static const _key = 'todo.notes.v1';

  SharedPrefsTodoStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<TodoNote>> load() async {
    try {
      final raw = await _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final map = jsonDecode(raw) as Map<String, Object?>;
      final list = (map['notes'] as List?)?.cast<Map<String, Object?>>() ?? [];
      return list.map(TodoNote.fromJson).toList();
    } catch (e) {
      debugPrint('SharedPrefsTodoStore.load failed: $e');
      return [];
    }
  }

  @override
  Future<void> save(List<TodoNote> notes) async {
    final payload = {
      'version': 1,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
    await _prefs.setString(_key, jsonEncode(payload));
  }
}

class MemoryTodoStore implements TodoStore { /* 测试 / 预览用 */ }
```

- 整份列表序列化成一段 JSON 字符串，存进 `todo.notes.v1`；杀进程、重启后数据仍在。
- 用 2.5 的 `SharedPreferencesAsync`：读写直接落到平台侧、不带进程内缓存，比旧的 `SharedPreferences` + `getInstance()` 少一层缓存不一致的坑。
- key 带版本：结构变了就读 `todo.notes.v2`，v1 留作迁移来源；`version` 字段同时兜底。
- `load()` 解析失败返回 `[]` 并 `debugPrint`，不把异常抛给 UI（坏数据最多丢一次，不能白屏）。
- 单条写入量是 KB 级，SharedPreferences 足够；真到成千上万条再换 sqflite / Isar，只改这一个实现。
- **接口的意义**：以后要换 sqflite / 云同步，只新增一个实现，`main.dart` 换一行。

### 4.5 `state/todo_controller.dart`

```dart
class TodoController extends ChangeNotifier {
  TodoController(this._store, {
    Duration saveDebounce = const Duration(milliseconds: 250), // 测试里调小
    DateTime Function()? now,                                  // 注入固定时钟
  });
  final TodoStore _store;
  final Duration saveDebounce;

  bool get isLoading;
  Object? get error;
  List<TodoNote> get all;

  List<TodoNote> get pending;                 // 未完成，createdAt 倒序
  List<TodoNote> get doneToday;               // completedAt 在今天，倒序
  int get todayTotal;                         // pending + doneToday
  List<TodoNote> doneOn(DateTime day);
  List<int> weeklyCounts(DateTime weekStart); // 7 个数，给柱状图
  int streakDays([DateTime? today]);          // 连续完成天数

  Future<void> load();
  Future<TodoNote> add({required String content, TodoCategory category = TodoCategory.work, String? timeLabel});
  Future<void> update(TodoNote note);
  Future<void> toggle(String id);
  Future<void> remove(String id);
  Future<void> flush();                       // 跳过防抖立即落盘（退出/进后台）
}

class TodoScope extends InheritedNotifier<TodoController> {
  const TodoScope({required TodoController controller, required super.child, super.key})
      : super(notifier: controller);
  static TodoController of(BuildContext context) => ...;      // 缺席时 assert
  static TodoController? maybeOf(BuildContext context);
}
```

行为约定：

- 写操作先改内存、`notifyListeners()`，再落盘；落盘用 250ms 防抖（`Timer`），避免连点勾选时反复写。
- `add()` 里生成 id：`DateTime.now().microsecondsSinceEpoch.toRadixString(36)`，不引 uuid 包。
- `toggle()` 用 `note.copyWith(completedAt: done ? DateTime.now() : null, clearCompletedAt: !done)`。
- `streakDays()`：从今天往回数「有完成记录」的连续天；今天还没完成时从昨天起算（当天不算断）。
- 周起点统一用**周一 00:00**（`DateTime.utc` 只用来算日期差，展示仍用本地时间）。

### 4.6 `utils/formatters.dart`

| 函数 | 输出 |
|---|---|
| `dayKicker(DateTime)` | `10 月 30 日 · 周五` |
| `weekKicker(DateTime weekStart)` | `十月 · 第五周`（周次 = 该周在本月的第几周） |
| `monthDay(DateTime)` | `10 月 25 日` |
| `weekRange(DateTime weekStart)` | `10.23 – 10.29` |
| `cnNumber(int)` | `五`（1–10 用汉字，>10 用数字） |
| `weekdayShort(int)` | `一`…`日`（周一开头） |
| `dateOnly / addDays / mondayOf` | 日期运算：去时分秒、按日历加减天、取周一 |
| `isSameDay / daysBetween` | 同日判断、纯日期差（UTC 计算，不受夏令时影响） |
| `dotDate(DateTime)` | `10.25`（图表坐标轴、周区间） |
| `weekOfMonth(DateTime weekStart)` | `5`（以该周周四所在月份归属，9.28 那周算十月第一周） |

全部纯函数、无状态，单测好写。

### 4.7 `widgets/`

| 文件 | 关键签名 | 说明 |
|---|---|---|
| `paper_scaffold.dart` | `PaperScaffold({required Widget body, Widget? bottomBar})`、`PaperCard({required Widget child, EdgeInsets? padding})` | `Stack`：底色 → `IgnorePointer(Image.asset(paper, repeat, opacity .07))` → `SafeArea(top:true,bottom:false)`。`bottomBar` 走 `Scaffold.bottomNavigationBar`，自动让开键盘与手势条 |
| `note_tile.dart` | `NoteTile({required TodoNote note, VoidCallback? onTap, VoidCallback? onToggle})` | 68 高、圆角 16、阴影 sm；标题 16/1.45，完成态灰 + 删除线；meta 行 = 分类 chip + 时间 + `·` + 备注（可选）；整行 `InkWell` 进编辑，勾选圈自己吃掉点击 |
| `check_circle.dart` | `CheckCircle({required bool done, VoidCallback? onTap, double size = 24})` | `CustomPainter` 画微微不圆的圈（贝塞尔扰动）；完成时填 `accent` 并画白勾，160ms 缩放 + 逐段描边；外层 44×44 命中区，`Semantics(label: done ? '标记为未完成' : '标记为完成')` |
| `category_chip.dart` | `CategoryChip({required TodoCategory category, bool dense = false})` | 高 22、内边距 0/9、字 11/w600、全圆角；配色见下表 |
| `diy_tabbar.dart` | `DiyTabBar({required int index, required ValueChanged<int> onSelect, required VoidCallback onAdd})`、`static double heightOf(BuildContext)` | `surface` 底 + 顶边 1px `line` + 上投影；三格等分；中间 44 圆钮上浮 18，`primary` 底 + 阴影 |
| `hero_notes_art.dart` | `HeroNotesArt({double width = 112})` | 三张旋转便签（沙色 / 浅绿 / 纸白描边）+ 三条横线 + 勾选圆点，画笔还原原型 SVG 的层叠与角度 |
| `day_bar_chart.dart` | `DayBarChart({required List<int> counts, required DateTime weekStart, required int selected, required ValueChanged<int> onSelect})` | 高度按 310:132 等比；柱宽 20、圆角 6、上限高度按 week 最大值归一；柱顶数字 12px，底部周几；底层手绘横线用两段三次贝塞尔；点按按 `dx / width * 7` 取整，键盘方向键可选支持 |
| `week_sheet.dart` | `Future<DateTime?> showWeekSheet(BuildContext context, {required DateTime weekStart, int weekCount = 0})` | `showModalBottomSheet(isScrollControlled: true, backgroundColor: transparent)`；顶部抓手 40×4；月历 6 行 × 7 列，**一行 = 一周**，选中行 `primarySoft` 底、字 `primaryDeep`；`<` `>` 切月，点标题切到年/月选择（4×3 网格）；底部「已选 10.23 – 10.29」+ 完成按钮 |

分类配色（工作 / 生活 / 学习 来自原型；**灵感是新增，原型只有药丸没有 chip 样式**）：

| 分类 | 底 | 字 |
|---|---|---|
| 工作 | `primarySoft` #F2E1D4 | `primaryDeep` #6F3218 |
| 生活 | `accentSoft` #E5EBDC | `link` #52703F |
| 学习 | `sandSoft` #F0E2CE | `primaryDeep` #6F3218 |
| 灵感 | `sand` #E9CFA9 | `text` #2B1D14 |

### 4.8 `screens/`

**`root_shell.dart`**

```dart
class RootShell extends StatefulWidget { /* int _index; */ }
// Scaffold(
//   body: PaperScaffold(body: IndexedStack(index: _index, children: const [HomePage(), StatsPage()])),
//   bottomNavigationBar: DiyTabBar(index: _index, onSelect: ..., onAdd: ...),
// )
```

- 回退键：`PopScope(canPop: _index == 0, onPopInvoked... → setState(_index = 0))`，在「回顾」按返回回「今天」，而不是直接退出。
- 切页不做转场（原型的标签栏是瞬时切换），保留 `IndexedStack` 状态。
- 「新建」不换 index，`Navigator.pushNamed('/note')` 盖全屏。

**`home_page.dart`**（内容层，不含 Scaffold）

```
ListView(padding: 20/0/20/(tabbar 高 + 24))
├─ Row[ Column[ kicker, display ], HeroNotesArt ]
├─ _ProgressRow[ '已完成 2 件 · 还有 3 件', 圆点 ×N ]
├─ _SectionLabel('未完成') + NoteTile × pending
├─ _SectionLabel('今天已完成') + NoteTile × doneToday
└─ 空态（两段都空时）：一行提示 + 艺术字
```

- 标题 `今天要做的\n五件事`：`N = pending.length`，0 时改成「今天都做完了」。
- 圆点：`total = pending + doneToday`，前 `done` 个填 `accent`；超过 8 个显示 8 个 + `…`。
- 分组标题右侧的细线用 `Expanded(Divider)` 或 `Container(height:1)` 实现。

**`note_form_page.dart`**

```dart
class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.note});   // null = 新建
  final TodoNote? note;
}
```

- `PaperScaffold(body: ListView(...), bottomBar: _ActionBar)`。
- 顶部自定义 nav：左关闭（`Icons.close_rounded`），编辑态右侧「删除」（`danger`，二次确认后 pop 并删除，带 SnackBar「已删除 · 撤销」）。
- 表单：`TextField`（6 行、`maxLength` 不设、`textInputAction: newline`）、分类药丸 4 个、**时间（可选）药丸**：不设置 / 上午 / 下午 / 傍晚 / 睡前（原型缺口，见 §12）。
- 保存：内容空则按钮禁用（灰 `surface2`）；保存后 `pop`。键盘弹出时保存栏跟键盘走（`Scaffold.resizeToAvoidBottomInset: true` 默认即可）。

**`stats_page.dart`**

```dart
class _StatsPageState {
  late DateTime _weekStart;   // 本周一
  int _selected = 0;          // 0..6
}
```

```
ListView
├─ Row[ kicker(weekKicker), 换一周按钮 ]
├─ display: '这周完成了 N 件'
├─ PaperCard: 完成 N 件 / 连续记录 N 天（竖分割线）
├─ PaperCard: '每天完成的件数' + 日期范围 + DayBarChart + 提示
└─ PaperCard: 某天标题 + 'N 件' + 明细（NoteTile 的紧凑变体或 _DayRow）
```

- 默认选中「本周完成最多的一天」，与原型一致。
- `换一周` → `showWeekSheet`，返回的周一写入 `_weekStart`，`_selected` 重置。
- 空周：柱状图全 0（保留基线）、明细显示「这天没有完成记录」。

### 4.9 `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TodoController(SharedPrefsTodoStore());
  await controller.load();               // 读 SharedPreferences，冷启动可接受
  runApp(TodoApp(controller: controller));
}

class TodoApp extends StatelessWidget {
  // TodoScope(controller: ..., child: MaterialApp(
  //   title: '今天', theme: AppTheme.light, initialRoute: '/',
  //   onGenerateRoute: (s) => switch (s.name) {
  //     '/'   => _page(const RootShell()),
  //     '/note' => _page(NoteFormPage(note: s.arguments as TodoNote?)),
  //     _     => _page(const RootShell()),
  //   },
  // ))
}
```

`_page` 统一带 `FadeUpwardsPageTransitionsBuilder`？不需要，用默认 Material 转场即可；表单页建议 `PageRouteBuilder` 从底部滑入（更像原型「新建」的层级感）。

---

## 5. 数据契约

```json
{
  "version": 1,
  "notes": [
    {
      "id": "m3k9x2a1",
      "content": "周五前把提案终稿发给 Amanda",
      "category": "work",
      "timeLabel": "14:00",
      "createdAt": "2026-10-30T09:12:00.000",
      "completedAt": null
    }
  ]
}
```

- `id`：36 进制时间戳，单机唯一即可。
- `category`：枚举名（`work/life/study/idea`），读到未知值回落 `work`（不丢数据）。
- `timeLabel`：可空；存用户填的原文，不做时间解析。
- `completedAt`：ISO8601 本地时间，含微秒；`null` 即未完成。
- 整个 payload 带 `version`（key 名也带版本），为以后「按天分组 / 加标签」留迁移入口。

---

## 6. 数据流

```
用户点勾 ──► TodoController.toggle(id)
                 │ 改内存 → notifyListeners() → UI 重建
                 └─ 250ms 防抖 ──► SharedPrefsTodoStore.save(all) ──► SharedPreferences 写 'todo.notes.v1'
冷启动 ──► main() await load() ──► SharedPrefsTodoStore.load() ──► 读同一个 key ──► 列表 ──► runApp
```

- UI 从不直接改 `TodoNote` 字段（模型不可变），一切走 controller。
- 派生数据（未完成 / 今天完成 / 周柱状 / 连续天数）全部由 controller 算，页面不写业务判断。
- 统计页与首页共享同一个 controller，勾选后两页同时正确。

---

## 7. 设计变量映射（tokens.css → tokens.dart）

| CSS | Dart | 用途 |
|---|---|---|
| `--color-bg` #F6EFE6 | `bg` | 纸张底色 |
| `--color-surface` #FFF9F2 | `surface` | 卡片、标签栏、弹层 |
| `--color-surface-2` #F1E6D8 | `surface2` | 轨道、次级底 |
| `--color-text` #2B1D14 | `text` | 正文 |
| `--color-muted` #6E5A4B | `muted` | 次要文字（≈5.7:1，别再浅） |
| `--color-line` #E7D9C8 | `line` | 分隔线、描边 |
| `--color-primary` #A9542A | `primary` | 关键操作、选中 |
| `--color-primary-ink` #FFFFFF | `primaryInk` | 主色上的字 |
| `--color-primary-soft` #F2E1D4 | `primarySoft` | 标签底 |
| `--color-primary-deep` #6F3218 | `primaryDeep` | 浅底上的小字 |
| `--color-accent` #5E7A4A | `accent` | 勾选、柱状选中 |
| `--color-accent-soft` #E5EBDC | `accentSoft` | 生活标签底 |
| `--color-link` #52703F | `link` | 小字强调 |
| `--color-sand` / `-deep` / `-soft` | `sand` / `sandDeep` / `sandSoft` | 插画、学习标签 |
| `--color-danger` #8C3B24 | `danger` | 删除 |

字号 12/14/16/20/24/32/40、间距 4/8/12/16/24/32/48/64、圆角 10/16/24/∞、阴影三档，原样搬。
动效：`--dur 200ms`、`--ease cubic-bezier(.2,.8,.2,1)`；系统开启「减弱动态效果」时，`AppMotion` 统一退化为 `Duration.zero`（读 `MediaQuery.disableAnimations`）。

---

## 8. 原型 → Flutter 对照

| 文件 | 原型来源 |
|---|---|
| `home_page.dart` | `home.html` |
| `note_form_page.dart` | `add.html` + `detail.html`（同一布局，编辑态多删除） |
| `stats_page.dart` | `stats.html` |
| `day_bar_chart.dart` | `stats.html` 里 `.chart` 的 SVG + 点击 JS |
| `week_sheet.dart` | `stats.html` 的 `#weekSheet` + 日历渲染 JS |
| `paper_scaffold.dart` | `app.css` 的 `body::after` 纸纹 + `.status-bar` |
| `note_tile.dart` | `app.css` `.todo` |
| `check_circle.dart` | `app.css` `.check` + 两套勾选 SVG |
| `category_chip.dart` | `app.css` `.chip` 三种配色 |
| `diy_tabbar.dart` | `app.css` `.tabbar` / `.tab-add .add-dot` |
| `hero_notes_art.dart` | `home.html` 的 `.hero-art` SVG |
| `app_theme.dart` | `tokens.css` + 各屏的 `.display` / `.headline` / `.card` |

---

## 9. 路由与交互

| 路由 | 页面 | 进入方式 |
|---|---|---|
| `/` | `RootShell`（今天 / 回顾） | 启动 |
| `/note` | `NoteFormPage`（参数 `TodoNote?`） | 标签栏「新建」、点待办行 |

- 标签栏切「回顾」只是 `_index = 1`，不压栈；返回键在 `_index != 0` 时先回「今天」。
- 新建/编辑保存后 `Navigator.pop`；编辑页删除后 `pop` 回首页并弹 SnackBar。
- 深链/分享暂不需要；将来要就换 `go_router`，页面文件不用动。

---

## 10. 资产方案

| 资产 | 规格 | 说明 |
|---|---|---|
| `fonts/NotoSerifSC-SemiBold.otf` | 字重 600 | 中文全量约 8–12MB。上线前用 `pyftsubset` 只留常用 3500 字 + 标点，可压到 1–2MB；`fontFamilyFallback: ['Songti SC', 'STSong', 'serif']` |
| `textures/paper.png` | 512×512 无缝、灰阶噪声 | 叠在整屏，`opacity .07`，`ImageRepeat.repeat`，`IgnorePointer`；用 `RepaintBoundary` 包住避免整页重绘 |
| `art/*.svg` | 预留 | 首屏插画当前用 `CustomPainter` 画（旋转、描边、阴影都精确可控，且不用加依赖）。将来换成可编辑插画时再加 `flutter_svg`，并把 SVG 里的 `var(--color-*)` 换成具体色值（`flutter_svg` 不解析 CSS 变量） |

字体没到位前：`fontFamily` 留空走系统字体，标题用 `w700` + 负字距近似，不影响布局验收。

---

## 11. 依赖与 pubspec

```yaml
dependencies:
  flutter: {sdk: flutter}
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.5.6  # 已装（pub 镜像可达）

flutter:
  uses-material-design: true
  assets:
    - assets/textures/
  fonts:
    - family: NotoSerifSC
      fonts:
        - asset: assets/fonts/NotoSerifSC-SemiBold.otf
          weight: 600
```

- 若走 SVG 插画再加 `flutter_svg: ^2.2.0` 与 `assets/art/`。
- **持久化用 `shared_preferences: ^2.5.6`**：整份待办序列化成一段 JSON，存在 key `todo.notes.v1`。Android 侧包 `shared_preferences_android 2.5.4` 要求 `minSdk 24`，本工程 Flutter 默认就是 24，无需改 Gradle；该包自带 Android 原生实现，首次构建会走 Gradle 拉依赖。
- 单测里若真要测 `SharedPrefsTodoStore`，先 `SharedPreferences.setMockInitialValues({})`；但业务单测一律注入 `MemoryTodoStore`，不碰平台通道。
- 构建环境注意：本机 pub 缓存在 `C:` 盘、工程在 `D:` 盘，Kotlin 增量编译会因「不同根路径」报错，因此 `android/gradle.properties` 里加了 `kotlin.incremental=false`（只影响编译速度）。若换机器，pub 缓存与工程同盘时可去掉。

---

## 12. 原型里的缺口（落地时必须补）

1. **时间没有输入口**：首页会显示 `14:00 / 傍晚 / 睡前`，但 add/detail 只有「做什么 + 分类」。→ 表单加「时间（可选）」一行药丸，`timeLabel` 存原文。
2. **「灵感」没有 chip 配色**：原型首页只出现工作/生活/学习。→ 用沙色底 + 墨色字（对比度 ≈9.8:1）。
3. **日历首日偏移是写死的**：`firstIndex()` 对 2026 年 10 月返回 6，只为让 10.23–10.29 占满一行。→ 一律用真实 `DateTime.weekday`，周一开头。
4. **状态栏和灵动岛是画上去的**（9:41、信号、电量）。→ 用系统状态栏 + `SafeArea` + 深色图标，不再画假图标。
5. **空状态缺失**：没有待办、没有今日完成、某天没有记录，三处都要文案。
6. **删除没有确认**：detail 页直接删除。→ 确认弹窗 + 删除后 SnackBar 可撤销。
7. **数字与文案写死**：「五件事」「14 件」「9 天」「10 月 29 日 · 周三」。→ 全部由 controller 派生。
8. **换一周不联动数据**：原型只改选中行。→ 周切换后柱状图、明细、标题一起重算。
9. **键盘遮挡**：表单底部有固定保存栏，需确认键盘弹起时按钮仍可见（`resizeToAvoidBottomInset` + `viewInsets`）。
10. **无障碍**：柱状图每根柱、勾选圈都要有语义标签；点击区 ≥44。

---

## 13. 落地顺序（每步可跑）

1. **骨架**：`tokens.dart` + `app_theme.dart` + `main.dart` + 空 `RootShell` + `PaperScaffold` + `DiyTabBar` → 能看到纸底和标签栏。
2. **数据层**：`todo_note.dart` + `todo_store.dart`（内存实现）+ `todo_controller.dart` + `todo_scope` → 写单测，先不接 UI。
3. **首页**：`note_tile` + `check_circle` + `category_chip` + `home_page`（接 controller，先用 seed 数据）。
4. **表单**：`note_form_page` 新建/编辑/删除 + 路由。
5. **回顾**：`day_bar_chart` + `week_sheet` + `stats_page`。
6. **资产与细节**：字体、纸纹、插画、动效、空状态、SnackBar。
7. **收尾**：`SharedPrefsTodoStore` 接上、冷启动验证（杀进程重开数据仍在）、更新 README。

验收清单：

- [ ] 390×844 下四屏无溢出、无截断；系统字号放大 1.3 倍仍可读
- [ ] 所有可点区域 ≥44×44
- [ ] 杀进程重开，数据与完成状态一致
- [ ] 勾选/取消后，首页计数、圆点、回顾柱状图同步变化
- [ ] 周切换跨月、跨年（12 月 → 1 月）正确
- [ ] 三处空状态文案正确
- [ ] `flutter analyze` 0 issue、`flutter test` 全绿
- [ ] 与 `design/*.html` 并排比对的视觉差异只剩字体（未装字体前）

---

## 14. 测试

| 文件 | 覆盖 |
|---|---|
| `test/models/todo_note_test.dart` | JSON 往返、`completedAt` 为 null、未知 category 回落、坏时间字符串 |
| `test/state/todo_controller_test.dart` | 增删改、toggle 的 completedAt、pending/doneToday 顺序、周计数、streak 边界（跨月、今天未完成） |
| `test/widget/home_page_test.dart` | 注入 `MemoryTodoStore` 后：标题件数、两段列表、空态 |

测试里永远用 `MemoryTodoStore`，不碰平台通道。要验证 `SharedPrefsTodoStore` 本身，先 `SharedPreferences.setMockInitialValues({})`，再走一遍 save → load。