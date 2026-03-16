import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/models/note.dart';

class Storage {
  /// Lấy collection notes của user đang đăng nhập.
  /// Path: users/{uid}/notes
  static CollectionReference<Map<String, dynamic>> _notesCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Chưa đăng nhập');
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
  }

  // ── Real-time stream ─────────────────────────────────────────────────────
  /// Stream của toàn bộ notes, sắp xếp theo thời gian chỉnh sửa mới nhất.
  static Stream<List<Note>> notesStream() {
    return _notesCollection()
        .orderBy('modifiedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Note(
                id: doc.id,
                title: (data['title'] as String?) ?? '',
                content: (data['content'] as String?) ?? '',
                attachments: _asStringList(data['attachments']),
                dueAt: _parseDateTime(data['dueAt']),
                modifiedAt: _parseModifiedAt(data['modifiedAt']),
              );
            }).toList());
  }

  // ── One-shot load ────────────────────────────────────────────────────────
  /// Load notes từ Firestore (one-shot).
  static Future<List<Note>> loadNotes() async {
    try {
      final query = await _notesCollection()
          .orderBy('modifiedAt', descending: true)
          .get();
      return query.docs.map((doc) {
        final data = doc.data();
        return Note(
          id: doc.id,
          title: (data['title'] as String?) ?? '',
          content: (data['content'] as String?) ?? '',
          attachments: _asStringList(data['attachments']),
          dueAt: _parseDateTime(data['dueAt']),
          modifiedAt: _parseModifiedAt(data['modifiedAt']),
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Storage.loadNotes failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── Individual CRUD ──────────────────────────────────────────────────────
  /// Thêm một note mới vào Firestore.
  static Future<void> addNote(Note note) async {
    try {
      await _notesCollection().doc(note.id).set(_noteToMap(note));
    } catch (error, stackTrace) {
      debugPrint('Storage.addNote failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Cập nhật một note đã tồn tại trong Firestore.
  static Future<void> updateNote(Note note) async {
    try {
      await _notesCollection().doc(note.id).set(_noteToMap(note));
    } catch (error, stackTrace) {
      debugPrint('Storage.updateNote failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Xóa một note khỏi Firestore theo id.
  static Future<void> deleteNote(String id) async {
    try {
      await _notesCollection().doc(id).delete();
    } catch (error, stackTrace) {
      debugPrint('Storage.deleteNote failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static Map<String, dynamic> _noteToMap(Note note) => {
        'title': note.title,
        'content': note.content,
        'attachments': note.attachments,
        'dueAt': note.dueAt != null ? Timestamp.fromDate(note.dueAt!) : null,
        'modifiedAt': Timestamp.fromDate(note.modifiedAt),
      };

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _parseModifiedAt(dynamic value) {
    return _parseDateTime(value) ?? DateTime.now();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
}
