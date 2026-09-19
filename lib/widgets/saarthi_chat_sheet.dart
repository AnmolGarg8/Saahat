import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/low_signal_controller.dart';
import '../services/saarthi_ai_service.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet providing the conversational interface for the Saarthi AI Journey Guide.
class SaarthiChatSheet extends StatefulWidget {
  const SaarthiChatSheet({super.key});

  /// Helper to open the sheet from any context.
  static Future<void> show(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isLowSignal ? Colors.black.withValues(alpha: 0.8) : Colors.black54,
      builder: (_) => const SaarthiChatSheet(),
    );
  }

  @override
  State<SaarthiChatSheet> createState() => _SaarthiChatSheetState();
}

class _SaarthiChatSheetState extends State<SaarthiChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default initial greeting message from Saarthi
    _messages.add(
      ChatMessage(
        role: 'assistant',
        text: "Hi, I'm Saarthi — your journey guide. Ask me anything about your route or the app.",
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final responseText = await SaarthiAiService.instance.sendMessage(
        userMessage: trimmed,
        conversationHistory: _messages,
      );

      if (mounted) {
        final isError = responseText == SaarthiAiService.fallbackErrorMessage;
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: responseText,
              isError: isError,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: SaarthiAiService.fallbackErrorMessage,
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    final activeRoute = SaarthiAiService.instance.activeRoute;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    final bgColor = isLowSignal ? AppTheme.lowSignalBg : Colors.white;
    final headerBg = isLowSignal ? const Color(0xFF141414) : const Color(0xFFF9F7FE);
    final borderColor = isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0);
    final textColor = isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B);

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isLowSignal ? Border.all(color: AppTheme.lowSignalBorder, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLowSignal
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isLowSignal ? AppTheme.lowSignalYellow : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: isLowSignal ? Colors.black : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Saarthi',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLowSignal
                                  ? AppTheme.lowSignalYellow.withValues(alpha: 0.2)
                                  : AppTheme.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AI Guide',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isLowSignal
                                    ? AppTheme.lowSignalYellow
                                    : AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        activeRoute != null
                            ? 'Context: ${activeRoute.title}'
                            : (isLowSignal ? 'Low Signal Mode: ON' : 'Journey Guide • Saahat'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isLowSignal ? const Color(0xFFCCCCCC) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Context Indicator Banner
          if (activeRoute != null || isLowSignal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isLowSignal
                    ? const Color(0xFF1F1F1F)
                    : const Color(0xFFEDE9FE),
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(
                    activeRoute != null ? Icons.route : Icons.signal_cellular_alt_1_bar,
                    size: 14,
                    color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activeRoute != null
                          ? 'Active Route: ${activeRoute.title} (${activeRoute.durationText})'
                          : 'Low Signal Mode is active',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Suggested Prompts (Chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPromptChip(
                    label: activeRoute != null ? 'Tell me about this route' : 'How does route scoring work?',
                    icon: Icons.navigation_rounded,
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                    label: 'What does the SOS button do?',
                    icon: Icons.emergency_rounded,
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                    label: 'How does Low Signal Mode work?',
                    icon: Icons.signal_cellular_alt,
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                    label: 'How does Share ETA protect my privacy?',
                    icon: Icons.shield_rounded,
                    isLowSignal: isLowSignal,
                  ),
                ],
              ),
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(isLowSignal);
                }
                final message = _messages[index];
                return _buildMessageBubble(message, isLowSignal);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isLowSignal ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Saarthi about your journey...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isLowSignal ? const Color(0xFF888888) : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color: isLowSignal ? Colors.black : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _sendMessage(_textController.text),
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

  Widget _buildPromptChip({
    required String label,
    required IconData icon,
    required bool isLowSignal,
  }) {
    return InkWell(
      onTap: () => _sendMessage(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLowSignal ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isLowSignal ? AppTheme.lowSignalText : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLowSignal) {
    final isUser = message.isUser;
    final isError = message.isError;

    final userBg = isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple;
    final userText = isLowSignal ? Colors.black : Colors.white;

    final assistantBg = isError
        ? (isLowSignal ? const Color(0xFF3B1515) : const Color(0xFFFEF2F2))
        : (isLowSignal ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC));

    final assistantBorder = isError
        ? (isLowSignal ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
        : (isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0));

    final assistantText = isError
        ? (isLowSignal ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
        : (isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: isLowSignal ? Colors.black : AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? userBg : assistantBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: assistantBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                      color: isUser ? userText : assistantText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isLowSignal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                size: 14,
                color: isLowSignal ? Colors.black : AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLowSignal ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: const TypingIndicatorDots(),
          ),
        ],
      ),
    );
  }
}

/// Three animated bouncing dots for the typing indicator.
class TypingIndicatorDots extends StatefulWidget {
  const TypingIndicatorDots({super.key});

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    final dotColor = isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final offset = (index * 0.2);
            final value = (_controller.value - offset) % 1.0;
            final double bounce = (value < 0.5) ? (value * 2) : (2.0 - value * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 7,
              height: 7,
              transform: Matrix4.translationValues(0, -3.5 * bounce, 0),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.3 + 0.7 * bounce),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
