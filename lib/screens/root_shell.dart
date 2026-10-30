import 'package:flutter/material.dart';

import '../widgets/diy_tabbar.dart';
import '../widgets/paper_scaffold.dart';
import 'home_page.dart';
import 'note_form_page.dart';
import 'stats_page.dart';

/// 应用外壳：`IndexedStack` 保住两页状态，标签栏只建一次。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static const routeName = '/';

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _openForm() {
    Navigator.of(context).pushNamed(NoteFormPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: PaperScaffold(
        body: IndexedStack(
          index: _index,
          children: const [HomePage(), StatsPage()],
        ),
        bottomBar: DiyTabBar(
          index: _index,
          onSelect: _select,
          onAdd: _openForm,
        ),
      ),
    );
  }
}