import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/models/note.dart';

class Storage {
  static const _kNotesKey = 'notes';

  /// Load notes stored as a single JSON string in SharedPreferences.
  /// The JSON is produced by `Note.listToJson` and parsed by `Note.listFromJson`.
  static Future<List<Note>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kNotesKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) return [];
      return Note.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  /// Save notes by converting the list into a JSON string via `Note.listToJson`
  /// and storing it in SharedPreferences.
  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = Note.listToJson(notes);
    await prefs.setString(_kNotesKey, jsonStr);
  }

  /// Optional convenience to clear stored notes.
  static Future<void> clearNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotesKey);
  }
}
