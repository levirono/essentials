import 'package:flutter/material.dart';
import '../database_helper.dart';

class FocusTimerHistoryPage extends StatefulWidget {
  @override
  FocusTimerHistoryPageState createState() => FocusTimerHistoryPageState();
}

class FocusTimerHistoryPageState extends State<FocusTimerHistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<FocusSession> _sessions = [];
  List<FocusSession> _filteredSessions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final sessions = await _dbHelper.getFocusSessions();
      setState(() {
        _sessions = sessions;
        _filteredSessions = sessions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sessions: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSessions = _sessions.where((session) {
        bool matchesType = _selectedFilter == 'all' || session.sessionType == _selectedFilter;
        bool matchesDate = _selectedDate == null || 
                          session.startTime.year == _selectedDate!.year &&
                          session.startTime.month == _selectedDate!.month &&
                          session.startTime.day == _selectedDate!.day;
        return matchesType && matchesDate;
      }).toList();
    });
  }

  String _getSessionTypeText(String type) {
    switch (type) {
      case 'focus': return 'Focus';
      case 'break': return 'Break';
      case 'long_break': return 'Long Break';
      default: return type;
    }
  }

  Color _getSessionTypeColor(String type) {
    switch (type) {
      case 'focus': return Colors.green;
      case 'break': return Colors.blue;
      case 'long_break': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getSessionTypeIcon(String type) {
    switch (type) {
      case 'focus': return Icons.psychology;
      case 'break': return Icons.coffee;
      case 'long_break': return Icons.hotel;
      default: return Icons.timer;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (sessionDate == today) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == yesterday) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Focus Timer History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 16),
                
                // Session Type Filter
                Text(
                  'Session Type:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'all',
                    'focus',
                    'break',
                    'long_break',
                  ].map((type) {
                    final isSelected = _selectedFilter == type;
                    return FilterChip(
                      label: Text(_getSessionTypeText(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = type);
                        _applyFilters();
                      },
                      selectedColor: colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: colorScheme.primary,
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 16),
                
                // Date Filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(Icons.calendar_today),
                        label: Text(_selectedDate == null 
                            ? 'Select Date' 
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.secondary,
                          side: BorderSide(color: colorScheme.secondary),
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: Icon(Icons.clear),
                        tooltip: 'Clear date filter',
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Results Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredSessions.length} sessions found',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedFilter != 'all' || _selectedDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'all';
                            _selectedDate = null;
                          });
                          _applyFilters();
                        },
                        child: Text('Clear All Filters'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sessions List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : _filteredSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No sessions found',
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or start a focus session!',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSessions,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _getSessionTypeColor(session.sessionType).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getSessionTypeIcon(session.sessionType),
                                              color: _getSessionTypeColor(session.sessionType),
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getSessionTypeText(session.sessionType),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getSessionTypeColor(session.sessionType),
                                                  ),
                                                ),
                                                Text(
                                                  _formatDateTime(session.startTime),
                                                  style: TextStyle(
                                                    color: colorScheme.onSurface.withOpacity(0.6),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: session.isCompleted 
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: session.isCompleted ? Colors.green : Colors.orange,
                                              ),
                                            ),
                                            child: Text(
                                              session.isCompleted ? 'Completed' : 'Incomplete',
                                              style: TextStyle(
                                                color: session.isCompleted ? Colors.green : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 16),
                                      
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoItem(
                                              'Duration',
                                              _formatDuration(session.duration),
                                              Icons.timer,
                                            ),
                                          ),
                                          if (session.endTime != null)
                                            Expanded(
                                              child: _buildInfoItem(
                                                'End Time',
                                                _formatDateTime(session.endTime!),
                                                Icons.schedule,
                                              ),
                                            ),
                                        ],
                                      ),
                                      
                                      if (session.notes != null && session.notes!.isNotEmpty) ...[
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Notes:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(session.notes!),
                                            ],
                                          ),
                                        ),
                                      ],
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
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.secondary,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
} 