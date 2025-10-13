import 'package:flutter/material.dart';
import 'package:flutter_auth_app/providers/auth_provider.dart';
import 'package:flutter_auth_app/services/advisor_history_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'skin_tips_history_detail_screen.dart';
import 'package:intl/intl.dart';

class SkinTipsHistoryScreen extends StatefulWidget {
  const SkinTipsHistoryScreen({super.key});

  @override
  State<SkinTipsHistoryScreen> createState() => _SkinTipsHistoryScreenState();
}

class _SkinTipsHistoryScreenState extends State<SkinTipsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _historyService = AdvisorHistoryService();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token == null) {
        throw Exception("You must be logged in to view history.");
      }

      final historyData = await _historyService.fetchAdvisorHistory(token: token);
      setState(() {
        _history = historyData;
        _filteredHistory = _history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistory = _history.where((item) {
        final skinQuery = item['query']?.toLowerCase() ?? '';
        final city = item['city']?.toLowerCase() ?? '';
        return skinQuery.contains(query) || city.contains(query);
      }).toList();
      // Deselect items that are no longer visible
      _selectedIds.removeWhere((id) => !_filteredHistory.any((item) => item['id'] == id));
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to delete')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    try {
      await _historyService.deleteAdvisorEntries(
        ids: _selectedIds.toList(),
        token: token,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected items deleted')),
        );
      }
      // Refresh the history list from the server
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete items: ${e.toString().replaceFirst("Exception: ", "")}'),
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _shareAdvice(String skinType, String? response) {
    Share.share(
      'Skin Care Advice\nSkin Type: $skinType\nResponse: $response',
      subject: 'AI Skin Advisor Recommendation',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Skin Advisor History'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.delete : Icons.delete_outline),
              tooltip: _isSelectionMode ? 'Delete Selected' : 'Select to Delete',
              onPressed: _isSelectionMode ? _deleteSelected : _toggleSelectionMode,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by skin type or city',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredHistory.isEmpty
                        ? const Center(
                            child: Text(
                              'No history available. Ask a question in AI Skin Advisor to start!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _filteredHistory.length,
                              itemBuilder: (context, index) {
                                final item = _filteredHistory[index];
                                final itemId = item['id'] as String;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.0),
                                    onTap: () {
                                      if (!_isSelectionMode) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SkinTipsHistoryDetailScreen(
                                                  item: item,
                                                  onShare: () => _shareAdvice( // Cast to Map<String, String> for detail screen
                                                    item['query'] ?? '',
                                                    item['response']!,
                                                  ),
                                                ),
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          if (_selectedIds.contains(itemId)) {
                                            _selectedIds.remove(itemId);
                                          } else {
                                            _selectedIds.add(itemId);
                                          }
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_isSelectionMode)
                                             Checkbox(
                                              value: _selectedIds.contains(itemId),
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value == true) {
                                                     _selectedIds.add(itemId);
                                                  } else {
                                                     _selectedIds.remove(itemId);
                                                  }
                                                });
                                              },
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Issue: ${item['query'] ?? 'No Query'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text('City: ${item['city'] ?? 'N/A'}'),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Time: ${item['timestamp'] != null ? DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(item['timestamp'])) : 'N/A'}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}