import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:WZipChat/widgets/chat_message_bubble.dart';
import 'package:WZipChat/models/chat_message.dart';
import 'package:WZipChat/providers/whatsapp_zip_provider.dart';

void main() {
  group('Link Launching Integration Tests', () {
    late WhatsappZipProvider mockProvider;

    setUpAll(() {
      // Disable provider type checking for tests
      Provider.debugCheckInvalidValueType = null;
    });

    setUp(() {
      mockProvider = WhatsappZipProvider();
    });

    Widget createTestWidget(ChatMessage message) {
      return MaterialApp(
        home: Scaffold(
          body: Provider<WhatsappZipProvider>.value(
            value: mockProvider,
            child: ChatMessageBubble(message: message),
          ),
        ),
      );
    }

    group('Basic Integration Tests', () {
      testWidgets('should handle web URL tap without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Visit https://example.com',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Tap on the message bubble
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();

        // Verify the widget is still there and didn't crash
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle PDF file tap without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Download document.pdf',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Verify PDF icon is present
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        
        // Tap on the message bubble
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();

        // Verify the widget is still there and didn't crash
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle document file tap without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Open document.docx',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Verify document icon is present
        expect(find.byIcon(Icons.description), findsOneWidget);
        
        // Tap on the message bubble
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();

        // Verify the widget is still there and didn't crash
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle multiple links without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Visit https://example.com and download file.pdf and open doc.txt',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Verify both icons are present
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        expect(find.byIcon(Icons.description), findsOneWidget);
        
        // Tap on the message bubble
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();

        // Verify the widget is still there and didn't crash
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle regular text without issues', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'This is just regular text',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Tap on the message bubble
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();

        // Verify the widget is still there and didn't crash
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle empty content gracefully', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: '',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Verify the widget renders
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });
    });
  });
}