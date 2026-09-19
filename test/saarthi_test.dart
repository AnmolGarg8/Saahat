import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saahat_app/config/api_config.dart';
import 'package:saahat_app/services/low_signal_controller.dart';
import 'package:saahat_app/services/saarthi_ai_service.dart';
import 'package:saahat_app/widgets/saarthi_chat_sheet.dart';
import 'package:saahat_app/widgets/saarthi_floating_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LowSignalController.instance.resetForTesting(false);
    SaarthiAiService.instance.clearActiveRoute();
    SaarthiAiService.instance.setMockClient(null);
    ApiConfig.aiProvider = 'openai';
    ApiConfig.openAiApiKey = '';
  });

  group('SaarthiAiService Context & Behavior Tests', () {
    test('buildSystemContext contains core app features and default state', () async {
      final context = await SaarthiAiService.instance.buildSystemContext();

      expect(context, contains('You are Saarthi'));
      expect(context, contains('Find Route'));
      expect(context, contains('SOS Emergency'));
      expect(context, contains('Low Signal & Battery Mode'));
      expect(context, contains('Share ETA'));
      expect(context, contains('Community Notes'));
      expect(context, contains('Low Signal & Battery Mode: OFF'));
      expect(context, contains('No specific route is currently selected'));
    });

    test('buildSystemContext includes active route details when provided', () async {
      SaarthiAiService.instance.setActiveRoute(
        const ActiveRouteInfo(
          title: 'Main Arterial Route',
          origin: 'IIT Delhi Main Gate',
          destination: 'Select Citywalk',
          durationText: '24 min',
          distanceText: '9.2 km',
          fitScore: 9.4,
          contextTag: 'Well-lit arterial road with active commercial corridor',
          pros: ['Continuous street lighting', 'Close to Hauz Khas Police Station'],
          cons: ['Moderate evening traffic near Outer Ring Road'],
        ),
      );

      final context = await SaarthiAiService.instance.buildSystemContext();

      expect(context, contains('Main Arterial Route'));
      expect(context, contains('IIT Delhi Main Gate'));
      expect(context, contains('Select Citywalk'));
      expect(context, contains('9.4 / 10'));
      expect(context, contains('Continuous street lighting'));
    });

    test('buildSystemContext reflects Low Signal Mode when ON', () async {
      LowSignalController.instance.setLowSignalMode(true);

      final context = await SaarthiAiService.instance.buildSystemContext();

      expect(context, contains('Low Signal & Battery Mode: ON'));
    });

    test('sendMessage returns fallback message when API key is missing or fails', () async {
      ApiConfig.openAiApiKey = '';
      final response = await SaarthiAiService.instance.sendMessage(
        userMessage: 'Hello',
      );

      expect(response, equals(SaarthiAiService.fallbackErrorMessage));
    });

    test('sendMessage handles HTTP 500 or network exception with graceful fallback', () async {
      ApiConfig.openAiApiKey = 'mock-key';
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      SaarthiAiService.instance.setMockClient(mockClient);

      final response = await SaarthiAiService.instance.sendMessage(
        userMessage: 'What routes are available?',
      );

      expect(response, equals(SaarthiAiService.fallbackErrorMessage));
    });

    test('sendMessage parses successful OpenAI API response correctly', () async {
      ApiConfig.openAiApiKey = 'mock-key';
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('api.openai.com/v1/chat/completions'));
        expect(request.headers['Authorization'], equals('Bearer mock-key'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['messages'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Hello! I am Saarthi, your journey guide on Saahat.',
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      SaarthiAiService.instance.setMockClient(mockClient);

      final response = await SaarthiAiService.instance.sendMessage(
        userMessage: 'hello',
      );

      expect(response, equals('Hello! I am Saarthi, your journey guide on Saahat.'));
    });
  });

  group('Saarthi Widgets Tests', () {
    testWidgets('SaarthiFloatingButton renders with icon and title', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SaarthiFloatingButton(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.text('Saarthi'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('SaarthiChatSheet displays branding, greeting, and suggested prompt chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SaarthiChatSheet(),
          ),
        ),
      );

      // Verify header & branding
      expect(find.text('Saarthi'), findsOneWidget);
      expect(find.text('AI Guide'), findsOneWidget);

      // Verify exact required initial greeting
      expect(
        find.text("Hi, I'm Saarthi — your journey guide. Ask me anything about your route or the app."),
        findsOneWidget,
      );

      // Verify suggestion chips
      expect(find.text('What does the SOS button do?'), findsOneWidget);
      expect(find.text('How does Low Signal Mode work?'), findsOneWidget);

      // Verify input field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask Saarthi about your journey...'), findsOneWidget);
    });
  });
}
