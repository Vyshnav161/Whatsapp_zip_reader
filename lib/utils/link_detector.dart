import 'dart:core';

enum LinkType { webUrl, pdfFile, documentFile, imageFile, videoFile }

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

/// A utility class for detecting and classifying different types of links in text.
/// 
/// This class provides functionality to:
/// - Detect web URLs, PDF files, and document files in text
/// - Classify links by type for appropriate handling
/// - Format URLs for launching in external applications
/// - Validate link formats
/// 
/// The detection is optimized for performance with compiled regex patterns
/// and efficient overlap detection algorithms.
class LinkDetector {
  // Enhanced web URL regex pattern - compiled once for performance
  static final RegExp _webUrlRegExp = RegExp(
    r'(https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}|[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[a-zA-Z]{2,}(?:/[^\s]*)?)',
    caseSensitive: false,
  );

  // PDF file regex pattern - compiled once for performance
  static final RegExp _pdfRegExp = RegExp(
    r'((?:https?://[^\s]*\.pdf(?:\?[^\s]*)?)|(?:www\.[^\s]*\.pdf(?:\?[^\s]*)?)|(?:[a-zA-Z]:\\[^\s]*\.pdf)|(?:~/[^\s]*\.pdf)|(?:/[^\s]*\.pdf)|(?:\b[^\s]*\.pdf\b))',
    caseSensitive: false,
  );

  // Document file regex pattern - compiled once for performance
  static final RegExp _documentRegExp = RegExp(
    r'((?:https?://[^\s]*\.(?:docx|doc|txt|rtf)(?:\?[^\s]*)?)|(?:www\.[^\s]*\.(?:docx|doc|txt|rtf)(?:\?[^\s]*)?)|(?:[a-zA-Z]:\\[^\s]*\.(?:docx|doc|txt|rtf))|(?:~/[^\s]*\.(?:docx|doc|txt|rtf))|(?:/[^\s]*\.(?:docx|doc|txt|rtf))|(?:\b[^\s]*\.(?:docx|doc|txt|rtf)\b))',
    caseSensitive: false,
  );

  // Image file regex pattern - compiled once for performance
  static final RegExp _imageRegExp = RegExp(
    r'((?:https?://[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg)(?:\?[^\s]*)?)|(?:www\.[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg)(?:\?[^\s]*)?)|(?:[a-zA-Z]:\\[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg))|(?:~/[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg))|(?:/[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg))|(?:\b[^\s]*\.(?:jpg|jpeg|png|gif|bmp|webp|svg)\b))',
    caseSensitive: false,
  );

  // Video file regex pattern - compiled once for performance
  static final RegExp _videoRegExp = RegExp(
    r'((?:https?://[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v)(?:\?[^\s]*)?)|(?:www\.[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v)(?:\?[^\s]*)?)|(?:[a-zA-Z]:\\[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v))|(?:~/[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v))|(?:/[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v))|(?:\b[^\s]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v)\b))',
    caseSensitive: false,
  );

  // Cache for recently processed texts to improve performance
  static final Map<String, List<DetectedLink>> _cache = {};
  static const int _maxCacheSize = 100;

  /// Detects all links in the given text and returns them as a list of DetectedLink objects.
  /// 
  /// This method uses caching to improve performance for repeated text processing.
  /// The detection prioritizes more specific patterns (PDF, documents) over general web URLs
  /// to avoid false positives.
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

    // Detect image files first (most specific pattern)
    for (final match in _imageRegExp.allMatches(text)) {
      links.add(DetectedLink(
        text: match.group(0)!,
        type: LinkType.imageFile,
        start: match.start,
        end: match.end,
      ));
    }

    // Detect video files
    for (final match in _videoRegExp.allMatches(text)) {
      // Check if this match overlaps with any existing image link
      if (!_overlapsWithExistingLinks(links, match.start, match.end)) {
        links.add(DetectedLink(
          text: match.group(0)!,
          type: LinkType.videoFile,
          start: match.start,
          end: match.end,
        ));
      }
    }

    // Detect PDF files
    for (final match in _pdfRegExp.allMatches(text)) {
      // Check if this match overlaps with any existing media link
      if (!_overlapsWithExistingLinks(links, match.start, match.end)) {
        links.add(DetectedLink(
          text: match.group(0)!,
          type: LinkType.pdfFile,
          start: match.start,
          end: match.end,
        ));
      }
    }

    // Detect document files
    for (final match in _documentRegExp.allMatches(text)) {
      // Check if this match overlaps with any existing link
      if (!_overlapsWithExistingLinks(links, match.start, match.end)) {
        links.add(DetectedLink(
          text: match.group(0)!,
          type: LinkType.documentFile,
          start: match.start,
          end: match.end,
        ));
      }
    }

    // Detect web URLs (least specific, so done last)
    for (final match in _webUrlRegExp.allMatches(text)) {
      // Check if this match overlaps with any existing link
      if (!_overlapsWithExistingLinks(links, match.start, match.end)) {
        links.add(DetectedLink(
          text: match.group(0)!,
          type: LinkType.webUrl,
          start: match.start,
          end: match.end,
        ));
      }
    }

    // Sort links by their start position for consistent ordering
    links.sort((a, b) => a.start.compareTo(b.start));

    // Cache the result for performance (with size limit)
    _cacheResult(text, links);

    return links;
  }

  /// Classifies a single link string and returns its type
  static LinkType classifyLink(String link) {
    if (_pdfRegExp.hasMatch(link)) return LinkType.pdfFile;
    if (_documentRegExp.hasMatch(link)) return LinkType.documentFile;
    return LinkType.webUrl;
  }

  /// Checks if a given range overlaps with any existing detected links
  static bool _overlapsWithExistingLinks(List<DetectedLink> existingLinks, int start, int end) {
    for (final link in existingLinks) {
      if ((start >= link.start && start < link.end) ||
          (end > link.start && end <= link.end) ||
          (start <= link.start && end >= link.end)) {
        return true;
      }
    }
    return false;
  }

  /// Formats a URL for launching by adding protocol if needed
  static String formatUrlForLaunching(String url, LinkType type) {
    // Clean up the URL first
    String cleanUrl = url.trim();
    
    switch (type) {
      case LinkType.webUrl:
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
      case LinkType.pdfFile:
      case LinkType.documentFile:
        // For file URLs, check if they need protocol
        if (cleanUrl.startsWith('www.')) {
          return 'https://$cleanUrl';
        } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
          return cleanUrl;
        } else if (cleanUrl.contains('.') && !cleanUrl.startsWith('/') && !cleanUrl.contains('\\')) {
          // Looks like a web URL for a file
          return 'https://$cleanUrl';
        }
        return cleanUrl;
    }
  }

  /// Validates if a link appears to be well-formed
  static bool isValidLink(String link, LinkType type) {
    switch (type) {
      case LinkType.webUrl:
        return _webUrlRegExp.hasMatch(link);
      case LinkType.pdfFile:
        return _pdfRegExp.hasMatch(link);
      case LinkType.documentFile:
        return _documentRegExp.hasMatch(link);
    }
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