import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '便签应用',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoNotesPage(),
    );
  }
}

// 便签数据模型
class TodoNote {
  String id;
  String content;
  DateTime createdAt;
  bool isCompleted;
  bool isUnlimited; // 是否为无限期待办事项

  TodoNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
    this.isUnlimited = false,
  });
}

class TodoNotesPage extends StatefulWidget {
  const TodoNotesPage({super.key});

  @override
  State<TodoNotesPage> createState() => _TodoNotesPageState();
}

class _TodoNotesPageState extends State<TodoNotesPage> {
  // 模拟数据
  late List<TodoNote> notes;

  @override
  void initState() {
    super.initState();
    notes = [
      TodoNote(
        id: '1',
        content: '需要完成 Q4 项目的详细提案文档',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TodoNote(
        id: '2',
        content: '周三下午 2 点团队例会',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TodoNote(
        id: '3',
        content: '审查新功能分支的 PR',
        createdAt: DateTime.now(),
      ),
      TodoNote(
        id: '4',
        content: '完成状态管理章节的学习',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isCompleted: true,
      ),
    ];
  }

  void _addNewNote() {
    showDialog(
      context: context,
      builder: (context) => _AddNoteDialog(
        onAdd: (content) {
          setState(() {
            notes.insert(
              0,
              TodoNote(
                id: DateTime.now().toString(),
                content: content,
                createdAt: DateTime.now(),
              ),
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

  void _toggleComplete(int index) {
    setState(() {
      notes[index].isCompleted = !notes[index].isCompleted;
    });
  }

  void _showCompletedItemsForDate(DateTime selectedDate) {
    final selectedDateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final completedItems = notes.where((n) {
      final noteDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return n.isCompleted && noteDate.isAtSameMomentAs(selectedDateKey);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日'),
        content: SizedBox(
          width: 300,
          child: completedItems.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      '该日期暂无完成事项',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: completedItems.length,
                  itemBuilder: (context, index) {
                    final note = completedItems[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.green[800],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  List<TodoNote> _getTodayCompletedNotes() {
    final today = DateTime.now();
    return notes.where((n) {
      final isSameDay = n.createdAt.year == today.year &&
          n.createdAt.month == today.month &&
          n.createdAt.day == today.day;
      return n.isCompleted && isSameDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的便签'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _UnlimitedNotesDialog(
                  notes: notes.where((n) => n.isUnlimited && !n.isCompleted).toList(),
                  onAdd: (content) {
                    setState(() {
                      notes.insert(
                        0,
                        TodoNote(
                          id: DateTime.now().toString(),
                          content: content,
                          createdAt: DateTime.now(),
                          isUnlimited: true,
                        ),
                      );
                    });
                  },
                  onDelete: (index) {
                    setState(() {
                      final unlimitedNotes = notes.where((n) => n.isUnlimited && !n.isCompleted).toList();
                      notes.remove(unlimitedNotes[index]);
                    });
                  },
                  onToggleComplete: (index) {
                    setState(() {
                      final unlimitedNotes = notes.where((n) => n.isUnlimited && !n.isCompleted).toList();
                      final note = unlimitedNotes[index];
                      note.isCompleted = !note.isCompleted;
                    });
                  },
                ),
              );
            },
            tooltip: '无限期待办',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null && mounted) {
                _showCompletedItemsForDate(selectedDate);
              }
            },
            tooltip: '查看完成日历',
          ),
        ],
      ),
      body: Column(
        children: [
          // 未完成事项
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '待办事项',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: notes.where((n) => !n.isCompleted).isEmpty
                      ? Center(
                          child: Text(
                            '没有待办事项',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: notes.where((n) => !n.isCompleted).length,
                          itemBuilder: (context, index) {
                            final filteredNotes = notes.where((n) => !n.isCompleted).toList();
                            final note = filteredNotes[index];
                            final originalIndex = notes.indexOf(note);
                            return _NoteCard(
                              note: note,
                              onDelete: () => _deleteNote(originalIndex),
                              onComplete: () => _toggleComplete(originalIndex),
                              formatDate: _formatDate,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // 今天已完成事项
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '今天完成',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _getTodayCompletedNotes().isEmpty
                      ? Center(
                          child: Text(
                            '还没有完成任何事项',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _getTodayCompletedNotes().length,
                          itemBuilder: (context, index) {
                            final note = _getTodayCompletedNotes()[index];
                            final originalIndex = notes.indexOf(note);
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('删除'),
                                        onTap: () => _deleteNote(originalIndex),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        tooltip: '添加新便签',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TodoNote note;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final String Function(DateTime) formatDate;

  const _NoteCard({
    required this.note,
    required this.onDelete,
    required this.onComplete,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: note.isCompleted
              ? Colors.grey[100]
              : Colors.blue[50],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Checkbox(
            value: note.isCompleted,
            onChanged: (_) => onComplete(),
          ),
          title: Text(
            note.content,
            style: TextStyle(
              fontSize: 15,
              decoration: note.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: note.isCompleted ? Colors.grey[600] : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              formatDate(note.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('编辑'),
                onTap: () {
                  // TODO: 实现编辑功能
                },
              ),
              PopupMenuItem(
                child: const Text('删除'),
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final Function(String content) onAdd;

  const _AddNoteDialog({required this.onAdd});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新便签'),
      content: TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          hintText: '输入便签内容',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        minLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_contentController.text.isNotEmpty) {
              widget.onAdd(_contentController.text);
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _UnlimitedNotesDialog extends StatefulWidget {
  final List<TodoNote> notes;
  final Function(String content) onAdd;
  final Function(int index) onDelete;
  final Function(int index) onToggleComplete;

  const _UnlimitedNotesDialog({
    required this.notes,
    required this.onAdd,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  State<_UnlimitedNotesDialog> createState() => _UnlimitedNotesDialogState();
}

class _UnlimitedNotesDialogState extends State<_UnlimitedNotesDialog> {
  final _contentController = TextEditingController();
  late List<TodoNote> _displayNotes;

  @override
  void initState() {
    super.initState();
    _displayNotes = List.from(widget.notes);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '无限期待办事项',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // 输入框和添加按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: '添加新的无限期待办事项',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_contentController.text.isNotEmpty) {
                      widget.onAdd(_contentController.text);
                      setState(() {
                        _displayNotes = List.from(widget.notes);
                      });
                      _contentController.clear();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // 事项列表
          Expanded(
            child: _displayNotes.isEmpty
                ? Center(
                    child: Text(
                      '暂无无限期待办事项',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _displayNotes.length,
                    itemBuilder: (context, index) {
                      final note = _displayNotes[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: note.isCompleted,
                              onChanged: (_) {
                                widget.onToggleComplete(index);
                                setState(() {
                                  _displayNotes = List.from(widget.notes);
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              iconSize: 20,
                              onPressed: () {
                                widget.onDelete(index);
                                setState(() {
                                  _displayNotes = List.from(widget.notes);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
