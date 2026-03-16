import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/models/note.dart';
import 'package:todo_list/services/supabase_media_service.dart';

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
  DateTime? _dueAt;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _attachments = List<String>.from(widget.note.attachments);
    _dueAt = widget.note.dueAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang tải tệp lên cloud, vui lòng đợi...'),
            ),
          );
          return;
        }

        final title = _titleController.text.trim();
        final content = _contentController.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tiêu đề không được để trống')),
          );
          return;
        }
        final updated = Note(
          id: widget.note.id,
          title: title,
          content: content,
          attachments: _attachments,
          dueAt: _dueAt,
          modifiedAt: DateTime.now(),
        );
        Navigator.of(context).pop(updated);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Xem / Sửa ghi chú')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickDueDateTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _dueAt == null
                            ? 'Thêm ngày giờ'
                            : DateFormat('dd/MM/yyyy HH:mm').format(_dueAt!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_dueAt != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Xóa ngày giờ',
                      onPressed: _isUploading ? null : _clearDueDateTime,
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Thêm ảnh'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Thêm video'),
                  ),
                ],
              ),
              if (_isUploading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Đang tải file lên Supabase...'),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final path = _attachments[index];
                    final isImage = SupabaseMediaService.looksLikeImage(path);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: isImage
                                ? Image.network(
                                    path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.videocam, size: 36),
                                      Text(
                                        path.split('/').last,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _attachments.removeAt(index)),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ),
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
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    border: OutlineInputBorder(),
                  ),
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
    await _uploadAttachment(file: file, mediaType: MediaType.image);
  }

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadAttachment(file: file, mediaType: MediaType.video);
  }

  Future<void> _uploadAttachment({
    required XFile file,
    required MediaType mediaType,
  }) async {
    setState(() => _isUploading = true);
    try {
      final uploadedUrl = await SupabaseMediaService.uploadXFile(
        file: file,
        mediaType: mediaType,
      );
      if (!mounted) return;
      setState(() => _attachments.add(uploadedUrl));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tải file thất bại: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now.add(const Duration(hours: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (selectedTime == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _clearDueDateTime() {
    setState(() {
      _dueAt = null;
    });
  }
}
