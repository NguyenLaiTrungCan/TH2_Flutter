import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MediaType { image, video }

class SupabaseMediaService {
  // Embedded defaults let `flutter run -d <device>` work without extra defines.
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wnpbzthhscdswpznbtar.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InducGJ6dGhoc2Nkc3dwem5idGFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwMzQxMTIsImV4cCI6MjA4ODYxMDExMn0.hxugZkNt9uWYuCRjXfrb_RX2xI7GrzoU4ErKPnC6VtQ',
  );
  static const String _bucketFromEnv = String.fromEnvironment(
    'SUPABASE_BUCKET',
    defaultValue: 'note-media',
  );

  static bool get isConfigured {
    return _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;
  }

  static String get configurationHelpMessage {
    return 'Thiếu cấu hình Supabase. Hãy cập nhật cấu hình mặc định hoặc chạy app với '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=... '
        '[--dart-define=SUPABASE_BUCKET=note-media]';
  }

  static String get _bucket {
    final bucket = _bucketFromEnv.trim();
    return bucket.isEmpty ? 'note-media' : bucket;
  }

  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('SupabaseMediaService.initialize: missing config, skip init.');
      return;
    }

    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static Future<String> uploadXFile({
    required XFile file,
    required MediaType mediaType,
  }) async {
    if (!isConfigured) {
      throw StateError(configurationHelpMessage);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Bạn cần đăng nhập trước khi tải tệp lên cloud.');
    }

    final sourceName = file.name.trim().isNotEmpty
        ? file.name.trim()
        : _basename(file.path);
    final fileExt = _extensionOf(sourceName);
    final normalizedExt = fileExt.isEmpty
        ? (mediaType == MediaType.image ? 'jpg' : 'mp4')
        : fileExt;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final folder = mediaType == MediaType.image ? 'images' : 'videos';
    final objectPath = '$uid/$folder/$timestamp.$normalizedExt';

    final bytes = await file.readAsBytes();

    await Supabase.instance.client.storage
        .from(_bucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentTypeForExtension(
              extension: normalizedExt,
              mediaType: mediaType,
            ),
          ),
        );

    return Supabase.instance.client.storage
        .from(_bucket)
        .getPublicUrl(objectPath);
  }

  static bool looksLikeImage(String value) {
    final ext = _extensionOf(value);
    return {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
      'svg',
    }.contains(ext);
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  static String _extensionOf(String value) {
    final sanitized = value.split('?').first;
    final fileName = _basename(sanitized);
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static String _contentTypeForExtension({
    required String extension,
    required MediaType mediaType,
  }) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return mediaType == MediaType.image
            ? 'application/octet-stream'
            : 'video/mp4';
    }
  }
}
