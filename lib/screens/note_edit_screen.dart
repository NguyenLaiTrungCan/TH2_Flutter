import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_list/models/note.dart';
import 'package:todo_list/services/storage.dart';

class NoteEditScreen extends StatefulWidget {
  final Note note;

  const NoteEditScreen({super.key, required this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();
  late List<String> _attachments;

  Future<bool> _onWillPop() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề không được để trống')),
      );
      return false;
    }
    final updated = Note(id: widget.note.id, title: title, content: content, modifiedAt: DateTime.now());
    Navigator.of(context).pop(updated);
    return false;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _attachments = List<String>.from(widget.note.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề không được để trống')),
      );
      return;
    }
    final updated = Note(id: widget.note.id, title: title, content: content, attachments: _attachments, modifiedAt: DateTime.now());
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xem / Sửa ghi chú'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Thêm ảnh'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Thêm video'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final path = _attachments[index];
                    final isImage = path.toLowerCase().endsWith('.png') || path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg') || path.toLowerCase().endsWith('.gif');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: isImage
                                ? Image.file(File(path), fit: BoxFit.cover)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [const Icon(Icons.videocam, size: 36), Text(File(path).uri.pathSegments.last, overflow: TextOverflow.ellipsis)],
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => setState(() => _attachments.removeAt(index)),
                              child: const Icon(Icons.close, size: 18, color: Colors.black54),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder()),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final saved = await Storage.saveAttachment(file.path);
    setState(() => _attachments.add(saved));
  }

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final saved = await Storage.saveAttachment(file.path);
    setState(() => _attachments.add(saved));
  }
}
