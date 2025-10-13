import 'package:flutter/material.dart';
import 'package:flutter_auth_app/screens/home/skin_tips_history_screen.dart';
import 'package:flutter_auth_app/services/ai_advisor_service.dart';
import 'package:flutter_auth_app/services/advisor_history_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_auth_app/providers/auth_provider.dart';

class SkinTipsPage extends StatefulWidget {
  const SkinTipsPage({super.key});

  @override
  State<SkinTipsPage> createState() => _SkinTipsPageState();
}

class _SkinTipsPageState extends State<SkinTipsPage> {
  final _queryController = TextEditingController();
  final _cityController = TextEditingController();
  final _advisorService = AiAdvisorService();
  final _historyService = AdvisorHistoryService();
  final ScrollController _scrollController = ScrollController();

  String? _response;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _queryController.clear();
    _cityController.clear();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _cityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_city', city);
    } catch (e) {
      // Suppress error to avoid blocking tip generation
    }
  }

  Future<void> _saveToHistory(String query, String city, String response) async {
    // No need to block UI, run in background
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) return; // Can't save if not logged in

    try {
      await _historyService.saveAdvisorEntry(
        query: query,
        city: city,
        response: response,
        token: token,
      );
    } catch (e) {
      // Silently fail or show a non-blocking toast
      debugPrint("Failed to save advisor history: $e");
    }
  }

  Future<void> _getAdvice() async {
    FocusScope.of(context).unfocus();
    if (_queryController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a query and your city.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
    });

    try {
      final start = DateTime.now();
      final result = await _advisorService.getAiAdvice(
        query: _queryController.text,
        city: _cityController.text,
      );
      print('API response time: ${DateTime.now().difference(start).inMilliseconds}ms');
      print('Response format: ${result.runtimeType}, Content: $result');
      setState(() {
        _response = result;
        _isLoading = false;
      });
      // Save data in background to avoid delaying tip display
      _saveCity(_cityController.text);
      _saveToHistory(_queryController.text, _cityController.text, result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _shareAdvice(String query, String response) {
    Share.share(
      'Skin Care Advice\nQuery: $query\nResponse: $response',
      subject: 'AI Skin Advisor Recommendation',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Skin Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SkinTipsHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        TextField(
                          controller: _queryController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Ask anything about your skin...',
                            hintText: 'e.g., How to reduce oily skin?',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Your City',
                            hintText: 'e.g., Mumbai, Delhi',
                            suffixIcon: IconButton(
                              tooltip: 'Get Advice',
                              icon: const Icon(Icons.send),
                              onPressed: _isLoading ? null : _getAdvice,
                            ),
                          ),
                          onSubmitted: (_) => _isLoading ? null : _getAdvice(),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildResponseWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildResponseWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (_response != null) {
      return Column(
        children: [
          Expanded(
            child: Markdown(
              controller: _scrollController,
              data: _response!,
              padding: const EdgeInsets.all(16.0),
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.5),
                listBullet: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share Advice',
              onPressed: () => _shareAdvice(_queryController.text, _response!),
            ),
          ),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your personal skin advisor is ready. Ask a question to begin!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}