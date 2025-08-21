import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/media_file.dart';
import '../utils/theme_utils.dart';
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

  // Helper method to make URLs clickable
  Widget _buildClickableText(String text) {
    // Regular expression to identify URLs
    final RegExp urlRegExp = RegExp(
      r'(https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );

    // If no URLs found, return simple text
    if (!urlRegExp.hasMatch(text)) {
      return Text(
        text,
        style: TextStyle(
          color: WhatsAppTheme.primaryTextColor,
          fontSize: 15,
        ),
        softWrap: true,
      );
    }

    // Split text by URLs
    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in urlRegExp.allMatches(text)) {
      // Add text before the URL
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              color: WhatsAppTheme.primaryTextColor,
              fontSize: 15,
            ),
          ),
        );
      }

      // Add the URL as a clickable link
      final url = text.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 15,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add any remaining text after the last URL
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
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
    );
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
                  _buildClickableText(message.content),
                  
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