import 'package:flutter/material.dart';
import 'package:todo_list/models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final String timeText;

  const NoteCard({super.key, required this.note, required this.timeText});

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
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                Text(
                  timeText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
