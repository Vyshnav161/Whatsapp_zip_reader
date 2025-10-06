import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:WZipChat/widgets/chat_message_bubble.dart';
import 'package:WZipChat/models/chat_message.dart';
import 'package:WZipChat/providers/whatsapp_zip_provider.dart';

void main() {
  group('ChatMessageBubble Link Functionality', () {
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

    group('Basic Functionality', () {
      testWidgets('should render web URLs without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Check out https://example.com for more info',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should render PDF files with icon', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Download the file document.pdf',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      });

      testWidgets('should render document files with icon', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Open the file document.docx',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
        expect(find.byIcon(Icons.description), findsOneWidget);
      });

      testWidgets('should handle multiple link types', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Visit https://example.com and download document.pdf or check notes.txt',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        expect(find.byIcon(Icons.description), findsOneWidget);
      });

      testWidgets('should handle regular text', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'This is just regular text with no links',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
        expect(find.byIcon(Icons.description), findsNothing);
      });

      testWidgets('should handle system messages', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'System',
          content: 'Call Connected',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle empty content', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: '',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });

      testWidgets('should handle tap interactions without crashing', (WidgetTester tester) async {
        final message = ChatMessage(
          sender: 'Test User',
          content: 'Visit https://example.com',
          timestamp: DateTime.now(),
          isMe: false,
        );

        await tester.pumpWidget(createTestWidget(message));
        
        // Tap on the message bubble (this will attempt to tap links)
        await tester.tap(find.byType(ChatMessageBubble));
        await tester.pump();
        
        // Verify no crash occurred
        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });
    });
  });
}