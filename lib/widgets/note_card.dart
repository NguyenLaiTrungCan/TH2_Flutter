import 'package:flutter/material.dart';
import 'package:todo_list/models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final String timeText;
  final String? dueText;
  final VoidCallback? onAddToCalendar;

  const NoteCard({
    super.key,
    required this.note,
    required this.timeText,
    this.dueText,
    this.onAddToCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (dueText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Hạn: $dueText',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeText,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                if (onAddToCalendar != null)
                  IconButton(
                    tooltip: 'Thêm Google Calendar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onAddToCalendar,
                    icon: Icon(
                      Icons.event_available,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
