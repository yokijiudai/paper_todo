import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:node/main.dart';

void main() {
  testWidgets('骨架首屏能渲染，标题与标签栏都在', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    expect(find.text('先把今天\n写下来。'), findsOneWidget);
    expect(find.text('今天'), findsWidgets);
    expect(find.text('回顾'), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('点「回顾」切到统计占位页，点「今天」切回来', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('回顾').last);
    await tester.pumpAndSettle();
    expect(find.text('这一周的\n节奏。'), findsOneWidget);

    await tester.tap(find.text('今天').last);
    await tester.pumpAndSettle();
    expect(find.text('先把今天\n写下来。'), findsOneWidget);
  });
}
