import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/chat_message.dart';
import '../models/media_file.dart';

class WhatsappZipProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _extractionPath;
  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> _filteredChatMessages = [];
  List<MediaFile> _mediaFiles = [];
  String? _errorMessage;
  bool _hasPermission = false;
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get extractionPath => _extractionPath;
  List<ChatMessage> get chatMessages => _searchQuery.isEmpty ? _chatMessages : _filteredChatMessages;
  List<MediaFile> get mediaFiles => _mediaFiles;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;
  String get searchQuery => _searchQuery;

  // Request storage permissions
  Future<bool> requestPermissions() async {
    bool permissionsGranted = false;
    
    // Check if Android 13 or higher (API level 33+)
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted &&
          await Permission.videos.request().isGranted &&
          await Permission.audio.request().isGranted) {
        permissionsGranted = true;
      }
    }
    
    // For Android 12 and below or other platforms
    if (!permissionsGranted) {
      final status = await Permission.storage.request();
      permissionsGranted = status.isGranted;
    }
    
    _hasPermission = permissionsGranted;
    notifyListeners();
    return _hasPermission;
  }

  // Pick and process ZIP file
  Future<bool> pickAndProcessZip() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get the selected file
      final file = File(result.files.single.path!);
      
      // Extract ZIP file
      final success = await extractZipFile(file);
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error processing ZIP file: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Extract ZIP file
  Future<bool> extractZipFile(File zipFile) async {
    try {
      // Read the Zip file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Get the app's temporary directory to extract files
      final tempDir = await getTemporaryDirectory();
      final extractionDir = Directory('${tempDir.path}/whatsapp_extract_${DateTime.now().millisecondsSinceEpoch}');
      
      if (!await extractionDir.exists()) {
        await extractionDir.create(recursive: true);
      }
      
      _extractionPath = extractionDir.path;

      // Extract each file
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final extractedFile = File('${extractionDir.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          
          // Process the file based on its type
          if (filename.toLowerCase().endsWith('.txt')) {
            await _processChatFile(extractedFile);
          } else {
            _processMediaFile(extractedFile);
          }
        }
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error extracting ZIP file: ${e.toString()}';
      return false;
    }
  }

  // Process chat export file
  Future<void> _processChatFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      _chatMessages = [];
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Check if the line starts with a timestamp pattern
        // Format 1: [DD/MM/YY, HH:MM:SS] Sender: Message
        // Format 2: DD/MM/YY, HH:MM - Sender: Message
        bool isValidMessageLine = 
            (line.startsWith('[') && line.contains(']')) || // Old format with brackets
            (RegExp(r'^\d{1,2}/\d{1,2}/\d{1,2}, \d{1,2}:\d{1,2} -').hasMatch(line)); // New format with dash
        
        if (isValidMessageLine) {
          try {
            final message = ChatMessage.fromExportLine(line);
            _chatMessages.add(message);
          } catch (e) {
            print('Error parsing message line: $line');
            print('Error details: $e');
          }
        }
      }
      
      // If no messages were parsed, add a system message
      if (_chatMessages.isEmpty) {
        print('No messages parsed from file: ${file.path}');
        // Add the raw content as a system message for debugging
        _chatMessages.add(ChatMessage(
          sender: 'System',
          content: 'Chat content could not be parsed. Raw content:\n\n${content.substring(0, content.length > 500 ? 500 : content.length)}${content.length > 500 ? '...' : ''}',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      }
    } catch (e) {
      _errorMessage = 'Error processing chat file: ${e.toString()}';
    }
  }

  // Process media file
  void _processMediaFile(File file) {
    try {
      final mediaFile = MediaFile.fromFile(file);
      _mediaFiles.add(mediaFile);
    } catch (e) {
      print('Error processing media file: ${e.toString()}');
    }
  }

  // Clear extracted files
  Future<void> clearExtractedFiles() async {
    if (_extractionPath != null) {
      final dir = Directory(_extractionPath!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _extractionPath = null;
      _chatMessages = [];
      _mediaFiles = [];
      notifyListeners();
    }
  }

  // Reset state
  void reset() {
    _isLoading = false;
    _extractionPath = null;
    _chatMessages = [];
    _filteredChatMessages = [];
    _mediaFiles = [];
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  // Search chat messages
  void searchMessages(String query) {
    _searchQuery = query.trim().toLowerCase();
    
    if (_searchQuery.isEmpty) {
      _filteredChatMessages = [];
    } else {
      _filteredChatMessages = _chatMessages.where((message) {
        return message.content.toLowerCase().contains(_searchQuery) ||
               message.sender.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    notifyListeners();
  }
  
  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredChatMessages = [];
    notifyListeners();
  }
}