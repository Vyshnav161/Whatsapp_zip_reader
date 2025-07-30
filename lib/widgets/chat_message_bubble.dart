import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../utils/theme_utils.dart';
import 'package:intl/intl.dart';

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
          Container(
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
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name (only show for incoming messages)
                if (!message.isMe)
                  Text(
                    message.sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getAvatarColor(message.sender),
                      fontSize: 13,
                    ),
                  ),
                
                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    color: WhatsAppTheme.primaryTextColor,
                    fontSize: 15,
                  ),
                ),
                
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
          
          // Avatar (only for outgoing messages)
          if (message.isMe) _buildAvatar(),
        ],
      ),
    );
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