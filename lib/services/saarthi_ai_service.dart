import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'low_signal_controller.dart';
import 'offline_cache_service.dart';

/// A single message in the Saarthi conversation.
class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String text;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': text,
      };
}

/// Information about a currently active or inspected route.
class ActiveRouteInfo {
  final String title;
  final String origin;
  final String destination;
  final String durationText;
  final String distanceText;
  final double fitScore;
  final String contextTag;
  final List<String> pros;
  final List<String> cons;
  final List<String> directions;

  const ActiveRouteInfo({
    required this.title,
    required this.origin,
    required this.destination,
    required this.durationText,
    required this.distanceText,
    required this.fitScore,
    required this.contextTag,
    this.pros = const [],
    this.cons = const [],
    this.directions = const [],
  });

  String toContextSummary() {
    final buffer = StringBuffer();
    buffer.writeln('- Route: "$title" from $origin to $destination');
    buffer.writeln('- Duration: $durationText, Distance: $distanceText');
    buffer.writeln('- Journey Fit Score: ${fitScore.toStringAsFixed(1)} / 10');
    buffer.writeln('- Condition Context: $contextTag');
    if (pros.isNotEmpty) {
      buffer.writeln('- Strengths: ${pros.join(', ')}');
    }
    if (cons.isNotEmpty) {
      buffer.writeln('- Considerations: ${cons.join(', ')}');
    }
    if (directions.isNotEmpty) {
      buffer.writeln('- Key steps: ${directions.take(4).join(' -> ')}');
    }
    return buffer.toString().trim();
  }
}

/// Service managing communication with the AI API for Saarthi.
class SaarthiAiService {
  static final SaarthiAiService instance = SaarthiAiService._internal();
  SaarthiAiService._internal();

  /// Default error message required when an API call fails.
  static const String fallbackErrorMessage =
      "I'm having trouble responding right now, try again in a moment";

  /// The active route currently inspected by the user.
  ActiveRouteInfo? activeRoute;

  /// Custom HTTP client instance for testing.
  http.Client? _httpClient;

  void setMockClient(http.Client? client) {
    _httpClient = client;
  }

  /// Sets the currently active route context.
  void setActiveRoute(ActiveRouteInfo? route) {
    activeRoute = route;
  }

  /// Clears the active route.
  void clearActiveRoute() {
    activeRoute = null;
  }

  /// Builds the rich, context-aware system prompt containing app state and feature knowledge.
  Future<String> buildSystemContext() async {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    // Check if we have active route or cached offline route
    ActiveRouteInfo? routeContext = activeRoute;
    if (routeContext == null) {
      final hasSaved = await OfflineCacheService.hasSavedRoute();
      if (hasSaved) {
        final cached = await OfflineCacheService.getLastCachedRoute();
        routeContext = ActiveRouteInfo(
          title: cached.routeTitle,
          origin: cached.origin,
          destination: cached.destination,
          durationText: cached.durationText,
          distanceText: cached.distanceText,
          fitScore: cached.fitScore,
          contextTag: cached.contextTag,
          directions: cached.steps.map((s) => s.instruction).toList(),
        );
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('You are Saarthi, an empathetic, intelligent, and safety-conscious AI journey guide for the Saahat navigation app.');
    buffer.writeln('Saahat helps travelers choose journeys that fit the moment — with clear options, real condition signals (lighting, footfall, transit, time-of-day), and privacy.');
    buffer.writeln('Saahat values:');
    buffer.writeln('1. "Real conditions, not just distance" — evaluates lighting, footfall, transit, time-of-day.');
    buffer.writeln('2. "No live tracking, ever" — zero continuous location logs, one-time ETA updates only.');
    buffer.writeln('3. "We describe, we never judge an area" — objective indicators, zero area stigma.');
    buffer.writeln('');
    buffer.writeln('### Core Saahat App Features:');
    buffer.writeln('1. Find Route: Evaluates routes based on safety signals (lighting, transit, footfall) and calculates a Journey Fit Score (out of 10). Supports offline route downloading for 100% offline access.');
    buffer.writeln('2. SOS Emergency: Tapping SOS opens a full-screen emergency panel showing the nearest police station and hospital with one-tap dialing, quick "Call Police" and "Call Emergency Contact" buttons, a temporary emergency location share toggle, and an "I\'m Safe Now" completion exit.');
    buffer.writeln('3. Low Signal & Battery Mode: A global high-contrast dark theme (OLED true black, high-contrast yellow text) that reduces battery drain and displays cached turn-by-turn directions, static map snapshots, and emergency help points with zero data usage.');
    buffer.writeln('4. Share ETA: Lets users share their route, travel time, and expected arrival time with trusted contacts (+91 Indian numbers) via native SMS pre-filled messages with no live tracking. Includes an "I\'ve Arrived Safely" celebration notification.');
    buffer.writeln('5. Community Notes: Crowdsourced, non-stigmatizing, time-bound community observations about route conditions (such as street lighting, construction, active transit stations).');
    buffer.writeln('');
    buffer.writeln('### Current App State:');
    buffer.writeln('- Low Signal & Battery Mode: ${isLowSignal ? "ON (High-contrast OLED mode active, optimized for low battery/offline)" : "OFF (Normal mode)"}');
    if (routeContext != null) {
      buffer.writeln('- Currently Inspected Route Details:');
      buffer.writeln(routeContext.toContextSummary());
    } else {
      buffer.writeln('- Currently Inspected Route Details: No specific route is currently selected.');
    }
    buffer.writeln('');
    buffer.writeln('### Response Guidelines:');
    buffer.writeln('- Keep responses concise, warm, helpful, and natural (1 to 3 short paragraphs).');
    buffer.writeln('- When the user asks about their route, use the exact route details provided above.');
    buffer.writeln('- When asked about app features (SOS, Low Signal Mode, Share ETA, Community Notes), explain them clearly based on Saahat\'s principles.');
    buffer.writeln('- Speak in friendly, reassuring tone. Avoid robotic disclaimers.');

    return buffer.toString();
  }

  /// Sends a message to the AI API with dynamic system context and returns the assistant's reply.
  Future<String> sendMessage({
    required String userMessage,
    List<ChatMessage> conversationHistory = const [],
  }) async {
    final customClient = _httpClient;
    final client = customClient ?? http.Client();
    final systemPrompt = await buildSystemContext();

    try {
      if (ApiConfig.aiProvider == 'anthropic') {
        return await _callAnthropic(client, systemPrompt, userMessage, conversationHistory);
      } else {
        return await _callOpenAi(client, systemPrompt, userMessage, conversationHistory);
      }
    } catch (e) {
      return fallbackErrorMessage;
    } finally {
      if (customClient == null) {
        client.close();
      }
    }
  }

  /// Calls OpenAI Chat Completions API (e.g. gpt-4o-mini).
  Future<String> _callOpenAi(
    http.Client client,
    String systemPrompt,
    String userMessage,
    List<ChatMessage> history,
  ) async {
    final apiKey = ApiConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      return fallbackErrorMessage;
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Include recent history (up to last 6 messages)
    for (final msg in history.take(6)) {
      if (!msg.isError) {
        messages.add({'role': msg.role, 'content': msg.text});
      }
    }

    messages.add({'role': 'user', 'content': userMessage});

    final response = await client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 500,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }

    return fallbackErrorMessage;
  }

  /// Calls Anthropic Messages API (e.g. claude-3-5-haiku-20241022).
  Future<String> _callAnthropic(
    http.Client client,
    String systemPrompt,
    String userMessage,
    List<ChatMessage> history,
  ) async {
    final apiKey = ApiConfig.anthropicApiKey.trim();
    if (apiKey.isEmpty) {
      return fallbackErrorMessage;
    }

    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final messages = <Map<String, String>>[];
    for (final msg in history.take(6)) {
      if (!msg.isError && (msg.role == 'user' || msg.role == 'assistant')) {
        messages.add({'role': msg.role, 'content': msg.text});
      }
    }
    messages.add({'role': 'user', 'content': userMessage});

    final response = await client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-3-5-haiku-20241022',
            'system': systemPrompt,
            'messages': messages,
            'max_tokens': 500,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final contentList = data['content'] as List?;
      if (contentList != null && contentList.isNotEmpty) {
        final text = contentList[0]['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }

    return fallbackErrorMessage;
  }
}
