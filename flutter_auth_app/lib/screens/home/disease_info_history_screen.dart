import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_auth_app/services/chat_history_service.dart';
import 'disease_info_detail_screen.dart';

class DiseaseInfoHistoryScreen extends StatefulWidget {
  final String token;
  const DiseaseInfoHistoryScreen({super.key, required this.token});

  @override
  State<DiseaseInfoHistoryScreen> createState() => _DiseaseInfoHistoryScreenState();
}

class _DiseaseInfoHistoryScreenState extends State<DiseaseInfoHistoryScreen> {
  final ChatHistoryService _diseaseHistoryService = ChatHistoryService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _diseaseEntries;
  List<Map<String, dynamic>> _filteredEntries = [];
  bool _isDeleteMode = false;
  final Set<String> _selectedEntries = {};

  @override
  void initState() {
    super.initState();
    _loadDiseaseEntries();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDiseaseEntries() {
    setState(() {
      _diseaseEntries = _diseaseHistoryService.getConversations(widget.token);
      _diseaseEntries.then((entries) {
        setState(() {
          _filteredEntries = entries;
        });
      });
    });
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _diseaseEntries.then((entries) {
        _filteredEntries = entries.where((entry) {
          final diseaseName = (entry['title'] ?? '').toLowerCase();
          return diseaseName.contains(query);
        }).toList();
        _selectedEntries.clear();
      });
    });
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        _selectedEntries.clear();
      }
    });
  }

  void _deleteSelectedEntries() async {
    if (_selectedEntries.isEmpty) {
      _toggleDeleteMode();
      return;
    }

    try {
      await _diseaseHistoryService.deleteConversations(
          widget.token, _selectedEntries.toList());
      _selectedEntries.clear();
      _isDeleteMode = false;
      _loadDiseaseEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entries: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDeleteMode ? 'Select Entries' : 'Disease History'),
        leading: _isDeleteMode
            ? IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _toggleDeleteMode,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.delete : Icons.delete_outline),
            onPressed: _isDeleteMode ? _deleteSelectedEntries : _toggleDeleteMode,
            tooltip: _isDeleteMode ? 'Delete Selected' : 'Delete History',
          ),
        ],
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by disease name',
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _diseaseEntries,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error, fontSize: 16),
                        ),
                      );
                    } else if (!snapshot.hasData || _filteredEntries.isEmpty) {
                      return const Center(
                        child: Text('No disease history found.', style: TextStyle(fontSize: 16)),
                      );
                    }

                    return ListView.builder(
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        final entryId = entry['id'] as String;
                        final isSelected = _selectedEntries.contains(entryId);
                        final timestamp = DateTime.parse(entry['timestamp']);
                        final formattedDate =
                            DateFormat('yyyy-MM-dd hh:mm a').format(timestamp);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: () {
                              if (_isDeleteMode) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedEntries.remove(entryId);
                                  } else {
                                    _selectedEntries.add(entryId);
                                  }
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiseaseInfoDetailScreen(
                                      entryId: entryId,
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isDeleteMode)
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedEntries.add(entryId);
                                          } else {
                                            _selectedEntries.remove(entryId);
                                          }
                                        });
                                      },
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry['title'] ?? 'Untitled',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}