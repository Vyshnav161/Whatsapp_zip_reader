# Design Document

## Overview

This feature enhances the existing chat message display functionality by improving URL detection and adding support for opening PDF and document files. The current implementation already has basic URL detection and clicking in the `ChatMessageBubble` widget, but we need to extend it to support document files and improve the visual differentiation between different types of links.

The solution will build upon the existing `_buildClickableText` method in `ChatMessageBubble` and extend the URL detection regex to include file patterns. We'll also enhance the visual styling to differentiate between web URLs, PDFs, and documents.

## Architecture

### Current Architecture
- `ChatMessage` model contains message content and metadata
- `ChatMessageBubble` widget renders messages with existing URL detection
- `url_launcher` package handles opening URLs in external browser
- Regex-based URL detection with `TapGestureRecognizer` for click handling

### Enhanced Architecture
- Extend existing URL detection regex to include file patterns
- Add file type detection logic to differentiate between URLs, PDFs, and documents
- Enhance visual styling with icons and different colors for different link types
- Improve error handling for failed file/URL launches
- Add support for local file paths and remote file URLs

## Components and Interfaces

### 1. Enhanced Link Detection Service
**Location**: Extend existing `_buildClickableText` method in `ChatMessageBubble`

**Responsibilities**:
- Detect web URLs (existing functionality)
- Detect PDF file paths and URLs
- Detect document file paths and URLs
- Classify link types for appropriate handling

**Interface**:
```dart
enum LinkType { webUrl, pdfFile, documentFile }

class DetectedLink {
  final String text;
  final LinkType type;
  final int start;
  final int end;
}
```

### 2. Enhanced Link Renderer
**Location**: Enhanced `_buildClickableText` method

**Responsibilities**:
- Render different link types with appropriate styling
- Add icons for file types
- Handle click events for different link types
- Provide visual feedback for link interactions

### 3. Link Handler Service
**Location**: New methods in `ChatMessageBubble`

**Responsibilities**:
- Open web URLs in browser (existing)
- Open PDF files in default PDF viewer
- Open document files in appropriate applications
- Handle errors gracefully with user feedback

## Data Models

### Enhanced Regular Expressions

**Web URLs** (existing, improved):
```dart
final RegExp webUrlRegExp = RegExp(
  r'(https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
  caseSensitive: false,
);
```

**PDF Files**:
```dart
final RegExp pdfRegExp = RegExp(
  r'((?:https?://|www\.|/|[a-zA-Z]:\\|~/)[^\s]*\.pdf(?:\?[^\s]*)?)',
  caseSensitive: false,
);
```

**Document Files**:
```dart
final RegExp documentRegExp = RegExp(
  r'((?:https?://|www\.|/|[a-zA-Z]:\\|~/)[^\s]*\.(?:doc|docx|txt|rtf)(?:\?[^\s]*)?)',
  caseSensitive: false,
);
```

### Link Classification Logic
```dart
LinkType _classifyLink(String link) {
  if (pdfRegExp.hasMatch(link)) return LinkType.pdfFile;
  if (documentRegExp.hasMatch(link)) return LinkType.documentFile;
  return LinkType.webUrl;
}
```

## Error Handling

### Launch Failure Handling
- Use `canLaunchUrl()` to check if URL/file can be opened before attempting
- Show user-friendly error messages using `ScaffoldMessenger`
- Fallback behavior for unsupported file types
- Graceful degradation when external applications are not available

### Error Message Strategy
```dart
void _showLaunchError(BuildContext context, String linkType) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Unable to open $linkType. Please check if you have an appropriate app installed.'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Testing Strategy

### Unit Tests
- Test regex patterns for different URL and file formats
- Test link classification logic
- Test error handling scenarios
- Test edge cases (malformed URLs, special characters)

### Widget Tests
- Test clickable text rendering with different link types
- Test visual styling for different link types
- Test tap gesture recognition
- Test error message display

### Integration Tests
- Test actual URL launching (with mocked `url_launcher`)
- Test file opening functionality
- Test user interaction flows
- Test accessibility features

### Test Cases to Cover
1. **Web URLs**:
   - `https://example.com`
   - `http://example.com`
   - `www.example.com`
   - `example.com`
   - URLs with paths, parameters, and fragments

2. **PDF Files**:
   - `https://example.com/document.pdf`
   - `/path/to/document.pdf`
   - `C:\Documents\file.pdf`
   - `~/Documents/file.pdf`

3. **Document Files**:
   - `.doc`, `.docx`, `.txt`, `.rtf` extensions
   - Local and remote paths
   - Mixed content messages

4. **Edge Cases**:
   - Multiple links in one message
   - Links with special characters
   - Malformed URLs
   - Very long URLs
   - Links at message boundaries

## Visual Design Specifications

### Link Styling
- **Web URLs**: Blue color with underline (existing)
- **PDF Files**: Red color with PDF icon and underline
- **Document Files**: Green color with document icon and underline

### Icon Integration
- Use Material Icons for file type indicators
- Icons positioned before the link text
- Consistent sizing (14px) for all icons

### Color Scheme
```dart
static const Color webLinkColor = Colors.blue;
static const Color pdfLinkColor = Colors.red;
static const Color documentLinkColor = Colors.green;
```

### Accessibility
- Maintain sufficient color contrast ratios
- Support screen readers with semantic labels
- Ensure touch targets meet minimum size requirements (44px)
- Provide alternative text for icons

## Implementation Approach

### Phase 1: Extend URL Detection
- Enhance existing regex patterns
- Add file type detection logic
- Maintain backward compatibility

### Phase 2: Visual Enhancement
- Add icons and color coding
- Implement different styling for link types
- Ensure consistent visual hierarchy

### Phase 3: Enhanced Launch Handling
- Improve error handling
- Add user feedback mechanisms
- Test cross-platform compatibility

### Phase 4: Testing and Polish
- Comprehensive testing across link types
- Performance optimization
- Accessibility improvements