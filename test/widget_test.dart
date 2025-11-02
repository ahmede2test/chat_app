import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/screens/chat_screen.dart';

void main() {
  testWidgets('ChatScreen can send a message and display it', (WidgetTester tester) async {
    // 1. Arrange: Wrap the ChatScreen in a MultiProvider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatService()),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    // 2. Act: Find the text field and type a message
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'Hello, test message!');

    // 3. Act: Tap the send button
    final sendButtonFinder = find.byIcon(Icons.send);
    await tester.tap(sendButtonFinder);

    // 4. Assert: Check if the message is displayed on the screen
    await tester.pump();
    expect(find.text('Hello, test message!'), findsOneWidget);
  });
}