import 'package:flutter_auth_app/models/chat_message.dart';
import 'package:flutter_auth_app/screens/home/disease_info_history_screen.dart';
import 'package:flutter_auth_app/services/chat_history_service.dart';
import 'package:flutter_auth_app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/gemini_service.dart';

class DiseaseInfoScreen extends StatefulWidget {
  final String? initialDisease;
  final List<ChatMessage>? initialMessages;
  final String token;
  final String? chatId;

  const DiseaseInfoScreen({
    super.key,
    this.initialDisease,
    this.initialMessages,
    required this.token,
    this.chatId,
  });

  @override
  State<DiseaseInfoScreen> createState() => _DiseaseInfoScreenState();
}

class _DiseaseInfoScreenState extends State<DiseaseInfoScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  List<ChatMessage> _messages = [];
  bool _loading = false;
  String? _error;
  int? _pendingAssistantIndex;
  String? _currentChatId;

  final List<String> _suggestions = const [
    'Eczema',
    'Acne',
    'Psoriasis',
    'Rosacea',
    'Melasma',
    'Vitiligo',
  ];

  @override
  void dispose() {
    _saveHistory();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveHistory() async {
    if (_messages.isNotEmpty) {
      try {
        final response = await _chatHistoryService.saveConversation(
          _messages,
          widget.token,
          chatId: _currentChatId,
        );
        if (_currentChatId == null && response.containsKey('chat_id')) {
          setState(() {
            _currentChatId = response['chat_id'];
          });
        }
        print("Disease history saved/updated successfully.");
      } catch (e) {
        print("Error saving disease history: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    if (widget.initialMessages != null) {
      _messages = widget.initialMessages!;
    } else if (widget.initialDisease != null &&
        widget.initialDisease!.isNotEmpty) {
      _fetchInfo(widget.initialDisease);
    }
  }

  Future<void> _fetchInfo([String? preset]) async {
    final query = (preset ?? _controller.text).trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _messages.add(ChatMessage(text: query, isUser: true));
      _controller.clear();
      _messages.add(const ChatMessage(text: 'Generating…', isUser: false));
      _pendingAssistantIndex = _messages.length - 1;
    });
    _scrollToEnd();

    try {
      final gemini = GeminiService(geminiApiKey);
      final text = await gemini.getDiseaseInfo(query);
      setState(() {
        if (_pendingAssistantIndex != null &&
            _pendingAssistantIndex! >= 0 &&
            _pendingAssistantIndex! < _messages.length) {
          _messages[_pendingAssistantIndex!] =
              ChatMessage(text: text, isUser: false);
        } else {
          _messages.add(ChatMessage(text: text, isUser: false));
        }
        _pendingAssistantIndex = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        final friendly = 'Could not fetch info. ${_error ?? ''}'.trim();
        if (_pendingAssistantIndex != null &&
            _pendingAssistantIndex! >= 0 &&
            _pendingAssistantIndex! < _messages.length) {
          _messages[_pendingAssistantIndex!] =
              ChatMessage(text: friendly, isUser: false);
        } else {
          _messages.add(ChatMessage(text: friendly, isUser: false));
        }
        _pendingAssistantIndex = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Disease Info',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              final selectedConversation =
                  await Navigator.push<List<ChatMessage>>(
                context,
                MaterialPageRoute(
                  builder: (context) => DiseaseInfoHistoryScreen(token: widget.token),
                ),
              );
              if (selectedConversation != null &&
                  selectedConversation.isNotEmpty) {
                setState(() {
                  _messages = selectedConversation;
                });
              }
            },
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          if (_messages.isEmpty)
            _SuggestionsRow(onTap: _fetchInfo, suggestions: _suggestions),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Align(
                    alignment:
                        m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85),
                      child: _Bubble(message: m),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _fetchInfo(),
                        decoration: InputDecoration(
                          hintText: 'Ask about a skin condition…',
                          hintStyle: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          prefixIcon: Icon(Icons.search,
                              color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          suffixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.mic_none_rounded,
                                color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                        style: TextStyle(color: colorScheme.onSurface),
                        cursorColor: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading ? null : _fetchInfo,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.send_rounded),
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
}

class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;
  const _SuggestionsRow({required this.onTap, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, i) {
            final s = suggestions[i];
            return ActionChip(
              label: Text(
                s,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              avatar: Icon(
                Icons.local_hospital_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => onTap(s),
              backgroundColor: colorScheme.surfaceContainerLow,
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 0.5,
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: suggestions.length,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    final bg =
        isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow;
    final fg = isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    final border = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: border,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: isUser
          ? Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            )
          : MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme)
                  .copyWith(p: theme.textTheme.bodyMedium?.copyWith(color: fg)),
            ),
    );
  }
}