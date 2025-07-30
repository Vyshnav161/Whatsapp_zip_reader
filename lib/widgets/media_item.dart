import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../models/media_file.dart';
import '../utils/theme_utils.dart';

class MediaItem extends StatefulWidget {
  final MediaFile mediaFile;

  const MediaItem({Key? key, required this.mediaFile}) : super(key: key);

  @override
  State<MediaItem> createState() => _MediaItemState();
}

class _MediaItemState extends State<MediaItem> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaFile.type == MediaType.video) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(widget.mediaFile.file);
    await _videoController!.initialize();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Open file with default app
  Future<void> _openFile() async {
    try {
      // For images, videos, and documents, show a full-screen preview
      if (widget.mediaFile.type == MediaType.image) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(widget.mediaFile.name),
                backgroundColor: WhatsAppTheme.appBarColor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: Icon(Icons.download),
                    onPressed: _saveFile,
                    tooltip: 'Download',
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(widget.mediaFile.file),
                ),
              ),
            ),
          ),
        );
      } else if (widget.mediaFile.type == MediaType.video) {
        // For video, show a video player screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(widget.mediaFile.name),
                backgroundColor: WhatsAppTheme.appBarColor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: Icon(Icons.download),
                    onPressed: _saveFile,
                    tooltip: 'Download',
                  ),
                ],
              ),
              body: Center(
                child: _videoController != null && _isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : CircularProgressIndicator(),
              ),
              floatingActionButton: _videoController != null && _isInitialized
                  ? FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                      child: Icon(
                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    )
                  : null,
            ),
          ),
        );
      } else if (widget.mediaFile.type == MediaType.document) {
        // For documents, show a preview dialog
        if (widget.mediaFile.name.toLowerCase().endsWith('.txt')) {
          final content = await widget.mediaFile.file.readAsString();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(widget.mediaFile.name),
                  backgroundColor: WhatsAppTheme.appBarColor,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: _saveFile,
                      tooltip: 'Download',
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Text(content),
                ),
              ),
            ),
          );
        } else {
          // For other document types, just show a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Document Preview'),
              content: Text('Cannot preview ${widget.mediaFile.name}. You can download it to view.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveFile();
                  },
                  child: Text('Download'),
                ),
              ],
            ),
          );
        }
      } else {
        // For other types, show a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Opening File'),
            content: Text('Opening ${widget.mediaFile.name}...'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Could not open file: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Get the downloads directory path
  Future<String> _getDownloadsPath() async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        // For Android, use the external storage directory
        directory = await getExternalStorageDirectory();
        
        // Navigate to the Downloads folder
        final String? externalPath = directory?.path;
        if (externalPath != null) {
          // The external path usually points to /storage/emulated/0/Android/data/com.example.app/files
          // We need to navigate to /storage/emulated/0/Download
          final List<String> pathSegments = externalPath.split('/');
          final String basePath = pathSegments.sublist(0, pathSegments.indexOf('Android')).join('/');
          return '$basePath/Download';
        }
      } else if (Platform.isIOS) {
        // For iOS, use the documents directory
        directory = await getApplicationDocumentsDirectory();
        return directory.path;
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // For desktop platforms, use the downloads directory
        directory = await getDownloadsDirectory();
        return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
      }
    } catch (e) {
      print('Error getting downloads path: $e');
    }
    
    // Fallback to temporary directory if all else fails
    directory = await getTemporaryDirectory();
    return directory.path;
  }
  
  // Save file to downloads
  Future<void> _saveFile() async {
    try {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Saving File'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Saving ${widget.mediaFile.name}...'),
            ],
          ),
        ),
      );
      
      // Get the downloads directory path
      final String downloadsPath = await _getDownloadsPath();
      final String destinationPath = '$downloadsPath/${widget.mediaFile.name}';
      
      // Create a copy of the file in the downloads directory
      final File sourceFile = widget.mediaFile.file;
      final File destinationFile = File(destinationPath);
      
      // Copy the file
      await sourceFile.copy(destinationPath);
      
      // Close the loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show success dialog with the path
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('File Saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.mediaFile.name} has been saved to:'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    destinationPath,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog if it's open
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Could not save file: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFile,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media preview
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              child: _buildMediaPreview(),
            ),
            
            // Media info
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mediaFile.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.mediaFile.formattedSize,
                        style: TextStyle(
                          color: WhatsAppTheme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.download, size: 20),
                        onPressed: _saveFile,
                        color: WhatsAppTheme.primaryColor,
                        tooltip: 'Download',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    switch (widget.mediaFile.type) {
      case MediaType.image:
        return Image.file(
          widget.mediaFile.file,
          fit: BoxFit.cover,
          height: 150,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
            );
          },
        );
        
      case MediaType.video:
        if (_isInitialized && _videoController != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
                backgroundColor: WhatsAppTheme.primaryColor.withOpacity(0.7),
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          );
        } else {
          return Container(
            height: 150,
            color: Colors.black,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
      case MediaType.audio:
        return Container(
          height: 100,
          color: Colors.blue[100],
          child: Center(child: Icon(Icons.audiotrack, size: 50, color: WhatsAppTheme.primaryColor)),
        );
        
      case MediaType.document:
        return Container(
          height: 100,
          color: Colors.orange[100],
          child: Center(child: Icon(Icons.insert_drive_file, size: 50, color: Colors.orange)),
        );
        
      case MediaType.unknown:
      default:
        return Container(
          height: 100,
          color: Colors.grey[200],
          child: Center(child: Icon(Icons.help_outline, size: 50, color: Colors.grey)),
        );
    }
  }
}