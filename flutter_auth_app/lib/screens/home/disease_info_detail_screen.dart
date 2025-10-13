import 'package:flutter/material.dart';
import 'package:flutter_auth_app/models/chat_message.dart';
import 'package:flutter_auth_app/services/chat_history_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class DiseaseInfoDetailScreen extends StatelessWidget {
  final String entryId;
  final String token;

  const DiseaseInfoDetailScreen({
    super.key,
    required this.entryId,
    required this.token,
  });

  // Parse Markdown-like text into styled widgets
  List<Widget> _parseMessageContent(String text, Color textColor, ThemeData theme) {
    if (text.isEmpty) {
      return [const SizedBox.shrink()];
    }

    return [
      MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          h1: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          h2: theme.textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          strong: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          listBullet: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        ),
        builders: {
          'ul': CustomListBuilder(),
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ChatHistoryService _diseaseHistoryService = ChatHistoryService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease History Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _diseaseHistoryService.getConversationDetails(token, entryId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.error,
                    ),
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'No details found.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final entry = snapshot.data!;
              final timestamp = DateTime.parse(entry['timestamp']);
              final formattedDate = DateFormat.yMMMd().add_jm().format(timestamp);
              final messages = (entry['messages'] as List)
                  .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disease Name: ${entry['title'] ?? 'Untitled'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Time: $formattedDate',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Conversation Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...messages.map((message) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12.0),
                              topRight: const Radius.circular(12.0),
                              bottomLeft: Radius.circular(message.isUser ? 12.0 : 4.0),
                              bottomRight: Radius.circular(message.isUser ? 4.0 : 12.0),
                            ),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.isUser ? 'You' : 'Assistant',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: message.isUser
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (message.isUser)
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                )
                              else
                                ..._parseMessageContent(
                                  message.text,
                                  colorScheme.onSurface,
                                  theme,
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Custom builder for unordered lists to match the style of DiseaseInfoScreen
class CustomListBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'ul') {
      return null;
    }

    final theme = preferredStyle ?? const TextStyle();
    final color = theme.color ?? Colors.black;

    // Check if children is not null; return empty column if it is
    if (element.children == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: element.children!.map((child) {
        if (child is md.Element && child.tag == 'li') {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                child: Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: color,
                ),
              ),
              Expanded(
                child: MarkdownBody(
                  data: child.textContent,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: theme,
                    strong: theme.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}