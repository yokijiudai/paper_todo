import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/note_form_page.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  runApp(const TodoApp());
}

/// 只负责三件事：主题、初始路由、新建/编辑页从底部滑入的转场。
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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