import 'dart:core';

enum LinkType { webUrl }

class DetectedLink {
  final String text;
  final LinkType type;
  final int start;
  final int end;

  DetectedLink({
    required this.text,
    required this.type,
    required this.start,
    required this.end,
  });

  @override
  String toString() {
    return 'DetectedLink(text: $text, type: $type, start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedLink &&
        other.text == text &&
        other.type == type &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode {
    return text.hashCode ^ type.hashCode ^ start.hashCode ^ end.hashCode;
  }
}

/// A utility class for detecting and classifying web URLs in text.
/// 
/// This class provides functionality to:
/// - Detect web URLs in text
/// - Format URLs for launching in external applications
/// - Validate URL formats
/// 
/// The detection is optimized for performance with compiled regex patterns.
class LinkDetector {
  // Web URL regex pattern - only matches actual web URLs, not file names
  static final RegExp _webUrlRegExp = RegExp(
    r'(https?://[^\s]+|www\.[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}(?:/[^\s]*)?)',
    caseSensitive: false,
  );





  // Cache for recently processed texts to improve performance
  static final Map<String, List<DetectedLink>> _cache = {};
  static const int _maxCacheSize = 100;

  // Common file extensions that should never be treated as web URLs
  static final Set<String> _fileExtensions = {
    // Audio files
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'opus', 'm4a', 'wma',
    // Video files  
    'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv', 'm4v',
    // Image files
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'tiff',
    // Document files
    'pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx',
    // Archive files
    'zip', 'rar', '7z', 'tar', 'gz',
    // Other common files
    'exe', 'dmg', 'pkg', 'deb', 'rpm'
  };

  /// Detects all web URLs in the given text and returns them as a list of DetectedLink objects.
  /// 
  /// This method uses caching to improve performance for repeated text processing.
  /// Excludes matches that appear to be file names based on common file extensions.
  /// 
  /// Returns an empty list if no links are found.
  static List<DetectedLink> detectLinks(String text) {
    // Check cache first for performance
    if (_cache.containsKey(text)) {
      return List.from(_cache[text]!);
    }

    // Early return for empty or very short text
    if (text.isEmpty || text.length < 4) {
      return [];
    }

    final List<DetectedLink> links = [];

    // Detect web URLs
    for (final match in _webUrlRegExp.allMatches(text)) {
      final matchText = match.group(0)!;
      
      // Skip if this looks like a file name with a common file extension
      if (_isLikelyFileName(matchText)) {
        continue;
      }
      
      links.add(DetectedLink(
        text: matchText,
        type: LinkType.webUrl,
        start: match.start,
        end: match.end,
      ));
    }

    // Sort links by their start position for consistent ordering
    links.sort((a, b) => a.start.compareTo(b.start));

    // Cache the result for performance (with size limit)
    _cacheResult(text, links);

    return links;
  }

  /// Checks if a matched string is likely a file name rather than a web URL
  static bool _isLikelyFileName(String text) {
    // Remove protocol if present for checking
    String checkText = text.toLowerCase();
    if (checkText.startsWith('http://') || checkText.startsWith('https://')) {
      return false; // Has protocol, likely a real URL
    }
    if (checkText.startsWith('www.')) {
      return false; // Starts with www, likely a real URL
    }
    
    // Check if it ends with a common file extension
    final lastDotIndex = checkText.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < checkText.length - 1) {
      final extension = checkText.substring(lastDotIndex + 1);
      // Remove any trailing path or query parameters
      final cleanExtension = extension.split('/')[0].split('?')[0];
      if (_fileExtensions.contains(cleanExtension)) {
        return true;
      }
    }
    
    return false;
  }

  /// Classifies a single link string and returns its type
  static LinkType classifyLink(String link) {
    return LinkType.webUrl;
  }



  /// Formats a URL for launching by adding protocol if needed
  static String formatUrlForLaunching(String url, LinkType type) {
    // Clean up the URL first
    String cleanUrl = url.trim();
    
    // Handle various URL formats
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return cleanUrl;
    } else if (cleanUrl.startsWith('www.')) {
      return 'https://$cleanUrl';
    } else if (cleanUrl.contains('.') && !cleanUrl.startsWith('/')) {
      // Looks like a domain, add https://
      return 'https://$cleanUrl';
    }
    return cleanUrl;
  }

  /// Validates if a link appears to be well-formed
  static bool isValidLink(String link, LinkType type) {
    return _webUrlRegExp.hasMatch(link);
  }

  /// Caches the detection result with size management
  static void _cacheResult(String text, List<DetectedLink> links) {
    // Manage cache size to prevent memory issues
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entries (simple FIFO approach)
      final keysToRemove = _cache.keys.take(_maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
    
    _cache[text] = List.from(links);
  }

  /// Clears the internal cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
  }

  /// Returns the current cache size (useful for monitoring)
  static int get cacheSize => _cache.length;
}