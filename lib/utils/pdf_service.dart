import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class PdfService {
  // WhatsApp-like colors
  static const PdfColor whatsappGreen = PdfColor.fromInt(0xFF128C7E);
  static const PdfColor whatsappLightGreen = PdfColor.fromInt(0xFFDCF8C6);
  static const PdfColor whatsappGray = PdfColor.fromInt(0xFFECE5DD);
  static const PdfColor whatsappDarkGray = PdfColor.fromInt(0xFF075E54);
  static const PdfColor whatsappBackground = PdfColor.fromInt(0xFFF0F0F0);
  static const PdfColor messageBubbleOther = PdfColor.fromInt(0xFFFFFFFF);
  
  static Future<String> generateChatPdf(List<ChatMessage> messages) async {
    final pdf = pw.Document();
    
    // Get the downloads directory and create WZipChat folder
    Directory? directory;
    
    if (Platform.isAndroid) {
      // For Android, use external storage downloads directory
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to app documents directory if external storage is not accessible
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // For other platforms, use documents directory
      directory = await getApplicationDocumentsDirectory();
    }
    
    final wZipChatDir = Directory('${directory.path}/WZipChat');
    
    // Create the directory if it doesn't exist
    if (!await wZipChatDir.exists()) {
      await wZipChatDir.create(recursive: true);
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'whatsapp_chat_$timestamp.pdf';
    final filePath = '${wZipChatDir.path}/$fileName';
    
    // Create a single page with all messages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          
          // Add header
          widgets.add(_buildChatHeader());
          widgets.add(pw.SizedBox(height: 20));
          
          // Group messages by date and add them
          String? currentDate;
          for (final message in messages) {
            final messageDate = DateFormat('yyyy-MM-dd').format(message.timestamp);
            
            // Add date header if date changed
            if (currentDate != messageDate) {
              if (currentDate != null) {
                widgets.add(pw.SizedBox(height: 16));
              }
              widgets.add(_buildDateHeader(message.timestamp));
              widgets.add(pw.SizedBox(height: 12));
              currentDate = messageDate;
            }
            
            widgets.add(_buildMessageWidget(message));
            widgets.add(pw.SizedBox(height: 8));
          }
          
          return widgets;
        },
      ),
    );
    
    // Save the PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }
  
  static pw.Widget _buildChatHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: whatsappDarkGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: whatsappGreen,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Center(
              child: pw.Text(
                'W',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WhatsApp Chat Export',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMessageWidget(ChatMessage message) {
    final isMe = message.sender == 'You';
    final timeFormat = DateFormat('HH:mm');
    
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: isMe ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar for other users
            pw.Container(
              width: 32,
              height: 32,
              margin: const pw.EdgeInsets.only(right: 8, top: 4),
              decoration: pw.BoxDecoration(
                color: whatsappGreen,
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Center(
                child: pw.Text(
                  message.sender.isNotEmpty ? message.sender[0].toUpperCase() : '?',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          
          // Message bubble
          pw.Flexible(
            child: pw.Container(
              constraints: const pw.BoxConstraints(maxWidth: 350),
              margin: pw.EdgeInsets.only(
                left: isMe ? 50 : 0,
                right: isMe ? 0 : 50,
              ),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: isMe ? whatsappLightGreen : messageBubbleOther,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: const pw.Radius.circular(12),
                    topRight: const pw.Radius.circular(12),
                    bottomLeft: pw.Radius.circular(isMe ? 12 : 4),
                    bottomRight: pw.Radius.circular(isMe ? 4 : 12),
                  ),
                  border: pw.Border.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats (when not "You")
                    if (!isMe && message.sender != 'You')
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          message.sender,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _getSenderColor(message.sender),
                          ),
                        ),
                      ),
                    
                    // Message content
                    _buildMessageContent(message),
                    
                    // Media attachment indicator
                    if (message.linkedMediaName != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 6),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isMe ? PdfColor.fromInt(0xFFE8F5E8) : whatsappGray,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              '📎',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(width: 4),
                            pw.Flexible(
                              child: pw.Text(
                                message.linkedMediaName!,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Time and status
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            timeFormat.format(message.timestamp),
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                          if (isMe) ...[
                            pw.SizedBox(width: 4),
                            pw.Text(
                              '✓✓',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: whatsappGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMessageContent(ChatMessage message) {
    final content = message.content;
    
    // Check if message contains edited indicator
    if (content.contains('<This message was edited>')) {
      final cleanContent = content.replaceAll('<This message was edited>', '').trim();
      
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (cleanContent.isNotEmpty)
            pw.Text(
              cleanContent,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
                lineSpacing: 1.2,
              ),
            ),
          if (cleanContent.isNotEmpty) pw.SizedBox(height: 4),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey500,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'i',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                'edited',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return pw.Text(
        content,
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.black,
          lineSpacing: 1.2,
        ),
      );
    }
  }
  
  static PdfColor _getSenderColor(String sender) {
    // Generate consistent colors for different senders
    final colors = [
      PdfColors.blue700,
      PdfColors.purple700,
      PdfColors.teal700,
      PdfColors.orange700,
      PdfColors.pink700,
      PdfColors.indigo700,
    ];
    
    final hash = sender.hashCode.abs();
    return colors[hash % colors.length];
  }
  
  static pw.Widget _buildDateHeader(DateTime date) {
    return pw.Container(
      width: double.infinity,
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: whatsappGray,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Text(
            _formatDateHeader(date),
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  static String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}