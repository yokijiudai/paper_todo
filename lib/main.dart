import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/seed_data.dart';
import 'data/todo_store.dart';
import 'screens/note_form_page.dart';
import 'screens/root_shell.dart';
import 'state/todo_controller.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

  final store = SharedPrefsTodoStore();
  final controller = TodoController(store);
  await controller.load();

  // 首次启动：磁盘上一条都没有时写入示例数据，免得一打开就是四屏皆空。
  // 先落盘再 load，让 controller 的内存状态与磁盘保持一致。
  if (controller.all.isEmpty && kSeedDemoOnFirstRun) {
    await store.save(demoNotes());
    await controller.load();
  }

  runApp(TodoApp(controller: controller));
}

/// 只负责三件事：把 controller 注入到整棵树、主题、新建/编辑页从底部滑入的转场。
class TodoApp extends StatefulWidget {
  const TodoApp({super.key, required this.controller});

  final TodoController controller;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // dispose 里不能 await；flush + controller.dispose 都会保证最后一次落盘。
    unawaited(widget.controller.flush());
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 退到后台时立刻落盘一次，别指望 250ms 的防抖窗口。
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.controller.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return TodoScope(
      controller: widget.controller,
      child: MaterialApp(
        title: '今天',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: RootShell.routeName,
        onGenerateRoute: (settings) {
          if (settings.name == NoteFormPage.routeName) {
            return _slideUpRoute(const NoteFormPage(), settings);
          }
          return MaterialPageRoute<void>(
            builder: (_) => const RootShell(),
            settings: settings,
          );
        },
      ),
    );
  }

  Route<void> _slideUpRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: AppMotion.base,
      reverseTransitionDuration: AppMotion.fast,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.ease,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
