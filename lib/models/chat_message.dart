class ChatMessage {
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isMe; // To determine if the message is from the current user

  ChatMessage({
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });

  // Factory method to parse a line from the chat export file
  factory ChatMessage.fromExportLine(String line) {
    // Expected formats:
    // 1. [DD/MM/YY, HH:MM:SS] Sender: Message content (old format with brackets)
    // 2. DD/MM/YY, HH:MM - Sender: Message content (new format without brackets)
    try {
      String timestampStr;
      String remainingText;
      
      // Check if the line uses the bracket format or dash format
      if (line.startsWith('[')) {
        // Old format with brackets
        final timestampEndIndex = line.indexOf(']');
        if (timestampEndIndex == -1) {
          throw FormatException('Invalid message format: missing timestamp closing bracket');
        }
        
        timestampStr = line.substring(1, timestampEndIndex).trim();
        remainingText = line.substring(timestampEndIndex + 1).trim();
      } else if (line.contains(' - ')) {
        // New format with dash
        final parts = line.split(' - ');
        if (parts.length < 2) {
          throw FormatException('Invalid message format: missing dash separator');
        }
        
        timestampStr = parts[0].trim();
        remainingText = parts[1].trim();
      } else {
        throw FormatException('Invalid message format: unknown format');
      }
      
      // Extract sender and content
      final senderEndIndex = remainingText.indexOf(':');
      
      if (senderEndIndex == -1) {
        // Special case for system messages without a sender
        return ChatMessage(
          sender: 'System',
          content: remainingText,
          timestamp: DateTime.now(),
          isMe: false,
        );
      }
      
      final sender = remainingText.substring(0, senderEndIndex).trim();
      final content = remainingText.substring(senderEndIndex + 1).trim();
      
      // Parse timestamp - this is a simplified version, might need adjustment based on actual format
      DateTime timestamp;
      try {
        // Try to parse different date formats
        final parts = timestampStr.split(', ');
        if (parts.length < 2) {
          throw FormatException('Invalid timestamp format: missing comma separator');
        }
        
        final datePart = parts[0];
        final timePart = parts[1];
        
        // Parse date (DD/MM/YY)
        final dateParts = datePart.split('/');
        if (dateParts.length < 3) {
          throw FormatException('Invalid date format: missing slashes');
        }
        
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);
        if (year < 100) year += 2000; // Assuming 2-digit year format
        
        // Parse time (HH:MM:SS or HH:MM:SS AM/PM or just HH:MM)
        String timeOnlyPart = timePart;
        bool isPM = false;
        
        if (timePart.contains('AM') || timePart.contains('PM')) {
          isPM = timePart.contains('PM');
          timeOnlyPart = timePart.replaceAll('AM', '').replaceAll('PM', '').trim();
        }
        
        final timeParts = timeOnlyPart.split(':');
        if (timeParts.isEmpty) {
          throw FormatException('Invalid time format: missing colon');
        }
        
        int hour = int.parse(timeParts[0]);
        int minute = 0;
        int second = 0;
        
        if (timeParts.length > 1) {
          minute = int.parse(timeParts[1]);
        }
        
        if (timeParts.length > 2) {
          second = int.parse(timeParts[2]);
        }
        
        // Adjust hour for PM
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        
        timestamp = DateTime(year, month, day, hour, minute, second);
      } catch (e) {
        // Fallback to current time if parsing fails
        timestamp = DateTime.now();
      }
      
      // Determine if the message is from the current user (simplified logic)
      // In a real app, you would compare with the current user's name
      const currentUserName = 'You'; // Placeholder, replace with actual logic
      final isMe = sender == currentUserName;
      
      // Process the content to replace specific patterns
      String processedContent = content;
      
      // Replace 'null' with 'Call Connected'
      if (processedContent == 'null') {
        processedContent = 'Call Connected';
      }
      
      // Replace '<Media omitted>' with 'Media Not Downloaded'
      if (processedContent == '<Media omitted>') {
        processedContent = 'Media Not Downloaded';
      }
      
      return ChatMessage(
        sender: sender,
        content: processedContent,
        timestamp: timestamp,
        isMe: isMe,
      );
    } catch (e) {
      // Return a default message for invalid lines
      return ChatMessage(
        sender: 'System',
        content: 'Invalid message format: $line',
        timestamp: DateTime.now(),
        isMe: false,
      );
    }
  }
}