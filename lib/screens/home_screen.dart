import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/models/note.dart';
import 'package:todo_list/widgets/note_card.dart';
import 'package:todo_list/screens/note_edit_screen.dart';
import 'package:todo_list/screens/note_create_screen.dart';
import 'package:todo_list/services/storage.dart';
import 'package:todo_list/services/theme_manager.dart';
import 'package:todo_list/widgets/search_bar.dart';

const String studentName = 'Nguyễn Lại Trung Cần';
const String studentId = '2351060421';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<Note> _allNotes = [];

  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final loaded = await Storage.loadNotes();
    setState(() {
      _allNotes.clear();
      _allNotes.addAll(loaded);
      _filteredNotes = List.from(_allNotes);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Note - $studentName - $studentId'),
        actions: [
          IconButton(
            tooltip: 'Chủ đề',
            icon: const Icon(Icons.palette),
            onPressed: _openThemeDialog,
          ),
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
                              setState(() {
                                _allNotes.removeWhere((n) => n.id == note.id);
                                _onSearchChanged();
                              });
                              await Storage.saveNotes(_allNotes);
                            },
                            child: InkWell(
                              onTap: () async {
                                final updated = await Navigator.of(context).push<Note>(
                                  MaterialPageRoute(
                                    builder: (_) => NoteEditScreen(note: note),
                                  ),
                                );
                                if (updated != null) {
                                  setState(() {
                                    final origIndex = _allNotes.indexWhere((n) => n.id == updated.id);
                                    if (origIndex != -1) {
                                      _allNotes[origIndex] = updated;
                                    }
                                    _onSearchChanged();
                                  });
                                  await Storage.saveNotes(_allNotes);
                                }
                              },
                              child: NoteCard(
                                  note: note, timeText: dateFmt.format(note.modifiedAt)),
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
          children: List.generate(6, (i) {
            final names = ['Teal (mặc định)', 'Indigo', 'Deep Orange', 'Pink', 'Green', 'Blue Grey'];
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
              groupValue: current,
              title: Text(names[i]),
              secondary: CircleAvatar(backgroundColor: colors[i]),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            );
          }),
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
      setState(() {
        _allNotes.insert(0, created);
        _onSearchChanged();
      });
      await Storage.saveNotes(_allNotes);
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
            color: Colors.grey.withOpacity(0.25),
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
