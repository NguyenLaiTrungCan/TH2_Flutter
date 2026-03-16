import 'package:todo_list/models/note.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  static const Duration _defaultEventDuration = Duration(minutes: 30);

  static bool canCreateEvent(Note note) => note.dueAt != null;

  static Future<bool> openCreateEvent(Note note) async {
    if (!canCreateEvent(note)) {
      return false;
    }

    final uri = _buildCreateEventUri(note);
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  static Uri _buildCreateEventUri(Note note) {
    final start = note.dueAt!.toUtc();
    final end = start.add(_defaultEventDuration);
    final title = note.title.trim().isEmpty ? 'Todo' : note.title.trim();
    final details = _buildDetails(note);

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'details': details,
      'dates': '${_formatCalendarDate(start)}/${_formatCalendarDate(end)}',
    });
  }

  static String _buildDetails(Note note) {
    final buffer = StringBuffer();
    final content = note.content.trim();

    if (content.isNotEmpty) {
      buffer.writeln(content);
    }

    if (note.attachments.isNotEmpty) {
      if (buffer.length > 0) {
        buffer.writeln();
      }
      buffer.writeln('Attachments:');
      for (final url in note.attachments) {
        buffer.writeln(url);
      }
    }

    return buffer.toString().trim();
  }

  static String _formatCalendarDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year$month${day}T$hour$minute${second}Z';
  }
}
