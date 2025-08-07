import 'dart:io';
import 'package:path/path.dart' as p;

enum MediaType {
  image,
  video,
  audio,
  document,
  unknown
}

class MediaFile {
  final File file;
  final MediaType type;
  final String name;
  final String path;
  final int size; // in bytes

  MediaFile({
    required this.file,
    required this.type,
    required this.name,
    required this.path,
    required this.size,
  });

  // Factory method to create a MediaFile from a File
  factory MediaFile.fromFile(File file) {
    final String extension = p.extension(file.path).toLowerCase();
    final MediaType type = _getMediaTypeFromExtension(extension);
    final String name = p.basename(file.path);
    final int size = file.lengthSync();

    return MediaFile(
      file: file,
      type: type,
      name: name,
      path: file.path,
      size: size,
    );
  }

  // Helper method to determine media type from file extension
  static MediaType _getMediaTypeFromExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
        return MediaType.image;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.webm':
        return MediaType.video;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.m4a':
      case '.aac':
      case '.opus':
        return MediaType.audio;
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.xls':
      case '.xlsx':
      case '.ppt':
      case '.pptx':
      case '.txt':
        return MediaType.document;
      default:
        return MediaType.unknown;
    }
  }

  // Format file size for display
  String get formattedSize {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (size >= gb) {
      return '${(size / gb).toStringAsFixed(2)} GB';
    } else if (size >= mb) {
      return '${(size / mb).toStringAsFixed(2)} MB';
    } else if (size >= kb) {
      return '${(size / kb).toStringAsFixed(2)} KB';
    } else {
      return '$size B';
    }
  }
}