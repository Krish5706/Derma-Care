import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class SkinTipsHistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onShare;

  const SkinTipsHistoryDetailScreen({
    super.key,
    required this.item,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Advice',
            onPressed: onShare,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue: ${item['query'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'City: ${item['city'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Time: ${item['timestamp'] != null ? DateFormat.yMMMd().add_jm().format(DateTime.parse(item['timestamp'])) : 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Response:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: item['response'] ?? 'No response available.',
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}