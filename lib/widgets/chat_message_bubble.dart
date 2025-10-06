import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/media_file.dart';
import '../utils/theme_utils.dart';
import '../utils/link_detector.dart';
import '../providers/whatsapp_zip_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'media_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';  // Add this import for TapGestureRecognizer

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({Key? key, required this.message}) : super(key: key);

  // Get initials from sender name
  String _getInitials(String name) {
    if (name == 'System') return 'S';
    
    final nameParts = name.split(' ');
    if (nameParts.isEmpty) return '';
    
    String initials = nameParts[0][0];
    if (nameParts.length > 1) {
      initials += nameParts[nameParts.length - 1][0];
    }
    
    return initials.toUpperCase();
  }
  
  // Get a consistent color based on the sender name
  Color _getAvatarColor(String name) {
    if (name == 'System') return Colors.grey;
    
    // Generate a consistent color based on the name
    final int hashCode = name.hashCode;
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return colors[hashCode.abs() % colors.length];
  }

  // Helper method to make URLs and files clickable
  // Optimized for performance with early returns and efficient text processing
  Widget _buildClickableText(String text, BuildContext context) {
    // Early return for empty text
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Detect all links in the text
    final List<DetectedLink> links = LinkDetector.detectLinks(text);

    // If no links found, return simple text widget (more efficient than RichText)
    if (links.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: WhatsAppTheme.primaryTextColor,
          fontSize: 15,
        ),
        softWrap: true,
      );
    }

    // Build text spans with clickable links
    final List<InlineSpan> spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final link in links) {
      // Add text before the link
      if (link.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, link.start),
            style: TextStyle(
              color: WhatsAppTheme.primaryTextColor,
              fontSize: 15,
            ),
          ),
        );
      }

      // Add the clickable link
      spans.add(_buildLinkSpan(link, context));

      lastEnd = link.end;
    }

    // Add any remaining text after the last link
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(
            color: WhatsAppTheme.primaryTextColor,
            fontSize: 15,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  /// Builds a clickable link span with appropriate icon and styling based on link type.
  /// 
  /// For file types (PDF, documents), includes an icon before the text.
  /// Web URLs are displayed without icons for cleaner appearance.
  InlineSpan _buildLinkSpan(DetectedLink link, BuildContext context) {
    final List<InlineSpan> linkSpans = [];

    // Add icon for file types
    if (link.type != LinkType.webUrl) {
      linkSpans.add(
        WidgetSpan(
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(
              _getLinkIcon(link.type),
              size: 14,
              color: _getLinkColor(link.type),
            ),
          ),
          alignment: PlaceholderAlignment.middle,
        ),
      );
    }

    // Add the link text
    linkSpans.add(
      TextSpan(
        text: link.text,
        style: TextStyle(
          color: _getLinkColor(link.type),
          fontSize: 15,
          decoration: TextDecoration.underline,
          fontWeight: link.type != LinkType.webUrl ? FontWeight.w500 : FontWeight.normal,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _handleLinkTap(link, context),
      ),
    );

    return TextSpan(children: linkSpans);
  }

  /// Returns the appropriate Material Icon for the given link type.
  IconData _getLinkIcon(LinkType type) {
    switch (type) {
      case LinkType.pdfFile:
        return Icons.picture_as_pdf;
      case LinkType.documentFile:
        return Icons.description;
      case LinkType.webUrl:
        return Icons.link; // Not used for web URLs
    }
  }

  /// Returns the appropriate color for the given link type.
  /// 
  /// - Web URLs: Blue (standard link color)
  /// - PDF files: Red (to indicate document type)
  /// - Document files: Green (to differentiate from PDFs)
  Color _getLinkColor(LinkType type) {
    switch (type) {
      case LinkType.webUrl:
        return Colors.blue;
      case LinkType.pdfFile:
        return Colors.red.shade600;
      case LinkType.documentFile:
        return Colors.green.shade600;
    }
  }

  /// Handles link tap events by routing to the appropriate launch method based on link type.
  void _handleLinkTap(DetectedLink link, BuildContext context) async {
    switch (link.type) {
      case LinkType.webUrl:
        await _launchWebUrl(link.text, context);
        break;
      case LinkType.pdfFile:
        await _launchPdfFile(link.text, context);
        break;
      case LinkType.documentFile:
        await _launchDocumentFile(link.text, context);
        break;
    }
  }

  /// Launches a web URL in the device's default external browser.
  /// 
  /// Automatically adds https:// protocol if missing.
  /// Shows user-friendly error message if launch fails.
  Future<void> _launchWebUrl(String url, BuildContext context) async {
    try {
      final String formattedUrl = LinkDetector.formatUrlForLaunching(url, LinkType.webUrl);
      final Uri uri = Uri.parse(formattedUrl);
      
      print('Attempting to launch URL: $formattedUrl');
      
      // Use the most reliable approach for mobile platforms
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      print('URL launch successful');
      
    } catch (e) {
      print('URL launch failed: $e');
      _showLaunchError('web link', 'Unable to open this link. Error: ${e.toString()}', context);
    }
  }

  /// Launches a PDF file in the device's default PDF viewer application.
  /// 
  /// Supports both local file paths and remote URLs.
  /// Shows user-friendly error message if launch fails.
  Future<void> _launchPdfFile(String filePath, BuildContext context) async {
    try {
      final String formattedUrl = LinkDetector.formatUrlForLaunching(filePath, LinkType.pdfFile);
      final Uri uri = Uri.parse(formattedUrl);
      
      print('Attempting to launch PDF: $formattedUrl');
      
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      print('PDF launch successful');
      
    } catch (e) {
      print('PDF launch failed: $e');
      _showLaunchError('PDF file', 'Unable to open PDF. Error: ${e.toString()}', context);
    }
  }

  /// Launches a document file in the appropriate default application.
  /// 
  /// Supports .doc, .docx, .txt, and .rtf files.
  /// Shows user-friendly error message if launch fails.
  Future<void> _launchDocumentFile(String filePath, BuildContext context) async {
    try {
      final String formattedUrl = LinkDetector.formatUrlForLaunching(filePath, LinkType.documentFile);
      final Uri uri = Uri.parse(formattedUrl);
      
      print('Attempting to launch document: $formattedUrl');
      
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      print('Document launch successful');
      
    } catch (e) {
      print('Document launch failed: $e');
      _showLaunchError('document file', 'Unable to open document. Error: ${e.toString()}', context);
    }
  }

  /// Shows a user-friendly error message when link launching fails.
  /// 
  /// Uses SnackBar to display the error with dismiss action.
  void _showLaunchError(String linkType, String additionalInfo, BuildContext context) {
    // Find the nearest scaffold context
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Unable to open $linkType. $additionalInfo'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    // For system messages, show a centered info card
    if (message.sender == 'System') {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: WhatsAppTheme.secondaryTextColor,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    // Check if this message has linked media
    Widget? linkedMediaWidget;
    if (message.linkedMediaName != null) {
      final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
      final mediaFile = provider.findMediaByName(message.linkedMediaName!);
      
      if (mediaFile != null) {
        linkedMediaWidget = Container(
          margin: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () {
              // Show the media in a dialog
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MediaItem(mediaFile: mediaFile),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getMediaIcon(mediaFile.type),
                    size: 16,
                    color: WhatsAppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      mediaFile.name,
                      style: TextStyle(
                        color: WhatsAppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    // For regular chat messages
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (only for incoming messages)
          if (!message.isMe) _buildAvatar(),
          
          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: !message.isMe ? 8 : 0,
                right: message.isMe ? 8 : 0,
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? WhatsAppTheme.outgoingMessageColor 
                    : WhatsAppTheme.incomingMessageColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name (only for incoming messages)
                  if (!message.isMe)
                    Text(
                      message.sender,
                      style: TextStyle(
                        color: _getAvatarColor(message.sender),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  
                  // Message content with clickable links
                  _buildClickableText(message.content, context),
                  
                  // Linked media if available
                  if (linkedMediaWidget != null) linkedMediaWidget,
                  
                  // Timestamp
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDateTime(message.timestamp),
                        style: TextStyle(
                          color: WhatsAppTheme.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get icon for media type
  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.document:
        return Icons.insert_drive_file;
      case MediaType.unknown:
      default:
        return Icons.attachment;
    }
  }
  
  // Build avatar widget with initials
  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _getAvatarColor(message.sender),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(message.sender),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Format timestamp to show only time (HH:MM)
  String _formatDateTime(DateTime time) {
    // Format time as HH:MM
    return DateFormat('HH:mm').format(time);
  }
}