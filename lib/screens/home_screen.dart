import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/models/note.dart';
import 'package:todo_list/widgets/note_card.dart';
import 'package:todo_list/screens/note_edit_screen.dart';
import 'package:todo_list/screens/note_create_screen.dart';
import 'package:todo_list/services/auth_service.dart';
import 'package:todo_list/services/google_calendar_service.dart';
import 'package:todo_list/services/storage.dart';
import 'package:todo_list/services/theme_manager.dart';
import 'package:todo_list/widgets/search_bar.dart';

const String studentName = 'Nguyễn Lại Trung Cần';
const String studentId = '2351060421';

class HomeScreen extends StatefulWidget {
  final String? welcomeName;

  const HomeScreen({super.key, this.welcomeName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Note> _allNotes = [];

  List<Note> _filteredNotes = [];
  StreamSubscription<List<Note>>? _notesSub;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _subscribeNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final welcomeName = widget.welcomeName?.trim();
      if (!mounted || welcomeName == null || welcomeName.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xin chào, $welcomeName!')),
      );
    });
  }

  void _subscribeNotes() {
    _notesSub = Storage.notesStream().listen(
      (notes) {
        if (!mounted) return;
        setState(() {
          _allNotes
            ..clear()
            ..addAll(notes);
          _onSearchChanged();
        });
      },
      onError: (error) => _showStorageError('lắng nghe', error),
    );
  }

  void _showStorageError(String action, Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi $action dữ liệu Firebase: $error')),
    );
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredNotes = List.from(_allNotes);
      } else {
        _filteredNotes = _allNotes
            .where((n) => n.title.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Người dùng';
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Note - $studentName', style: const TextStyle(fontSize: 15)),
            Text(studentId, style: const TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chủ đề',
            icon: const Icon(Icons.palette),
            onPressed: _openThemeDialog,
          ),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 18,
                foregroundImage: (photoUrl != null && photoUrl.trim().isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                onForegroundImageError: (Object error, StackTrace? stackTrace) {
                  // Ignore avatar fetch failures (e.g. Google 429) and keep fallback text.
                },
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (user?.email != null)
                      Text(user!.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await AuthService.signOut();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: NoteSearchBar(controller: _searchController),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return Dismissible(
                            key: ValueKey(note.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              color: Theme.of(context).colorScheme.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xác nhận'),
                                  content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Hủy')),
                                    ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Xóa')),
                                  ],
                                ),
                              );
                              return res == true;
                            },
                            onDismissed: (direction) async {
                              try {
                                await Storage.deleteNote(note.id);
                              } catch (error) {
                                _showStorageError('xóa', error);
                              }
                            },
                            child: InkWell(
                              onTap: () async {
                                final updated = await Navigator.of(context).push<Note>(
                                  MaterialPageRoute(
                                    builder: (_) => NoteEditScreen(note: note),
                                  ),
                                );
                                if (updated != null) {
                                  try {
                                    await Storage.updateNote(updated);
                                  } catch (error) {
                                    _showStorageError('cập nhật', error);
                                  }
                                }
                              },
                              child: NoteCard(
                                note: note,
                                timeText: dateFmt.format(note.modifiedAt),
                                dueText: note.dueAt != null
                                    ? dateFmt.format(note.dueAt!)
                                    : null,
                                onAddToCalendar:
                                    GoogleCalendarService.canCreateEvent(note)
                                    ? () => _addToGoogleCalendar(note)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openThemeDialog() async {
    final current = ThemeManager().themeIndex.value;
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Chọn chủ đề'),
          children: [
            RadioGroup<int>(
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              child: Column(
                children: List.generate(6, (i) {
                  const names = ['Teal (mặc định)', 'Indigo', 'Deep Orange', 'Pink', 'Green', 'Blue Grey'];
                  final colors = [
                    Colors.teal,
                    Colors.indigo,
                    Colors.deepOrange,
                    Colors.pink,
                    Colors.green,
                    Colors.blueGrey,
                  ];
                  return RadioListTile<int>(
                    value: i,
                    title: Text(names[i]),
                    secondary: CircleAvatar(backgroundColor: colors[i]),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      await ThemeManager().setTheme(selected);
    }
  }

  void _showAddNoteSheet() async {
    final created = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (_) => const NoteCreateScreen()),
    );
    if (created != null) {
      try {
        await Storage.addNote(created);
      } catch (error) {
        _showStorageError('thêm', error);
      }
    }
  }

  Future<void> _addToGoogleCalendar(Note note) async {
    if (!GoogleCalendarService.canCreateEvent(note)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy thêm ngày giờ trước khi đồng bộ Google Calendar.'),
        ),
      );
      return;
    }

    final opened = await GoogleCalendarService.openCreateEvent(note);
    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Calendar trên thiết bị này.'),
        ),
      );
    }
  }

  

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 120,
            color: Colors.grey.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có ghi chú nào, hãy tạo mới nhé!',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
