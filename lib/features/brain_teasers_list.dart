import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'brain_teaser_detail.dart';
import 'create_brain_teaser.dart';

class BrainTeasersListPage extends StatefulWidget {
  @override
  _BrainTeasersListPageState createState() => _BrainTeasersListPageState();
}

class _BrainTeasersListPageState extends State<BrainTeasersListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<BrainTeaser> _teasers = [];
  List<BrainTeaser> _filteredTeasers = [];
  List<String> _categories = [];
  String? _selectedCategory;
  int? _selectedDifficulty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Insert sample data if none exists
      await _dbHelper.insertSampleBrainTeasers();
      
      // Load teasers and categories
      final teasers = await _dbHelper.getBrainTeasers();
      final categories = await _dbHelper.getBrainTeaserCategories();
      
      setState(() {
        _teasers = teasers;
        _filteredTeasers = teasers;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading brain teasers: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTeasers = _teasers.where((teaser) {
        bool matchesCategory = _selectedCategory == null || 
                             teaser.category == _selectedCategory;
        bool matchesDifficulty = _selectedDifficulty == null || 
                               teaser.difficulty == _selectedDifficulty;
        return matchesCategory && matchesDifficulty;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDifficulty = null;
      _filteredTeasers = _teasers;
    });
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1: return 'Easy';
      case 2: return 'Medium';
      case 3: return 'Hard';
      default: return 'Unknown';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Brain Teasers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateBrainTeaserPage()),
              );
              if (result == true) {
                _loadData();
              }
            },
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text('All Categories')),
                          ..._categories.map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedDifficulty,
                        decoration: InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text('All Levels')),
                          DropdownMenuItem(value: 1, child: Text('Easy')),
                          DropdownMenuItem(value: 2, child: Text('Medium')),
                          DropdownMenuItem(value: 3, child: Text('Hard')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDifficulty = value);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredTeasers.length} teasers found',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear),
                      label: Text('Clear Filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Teasers List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : _filteredTeasers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No brain teasers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or create a new teaser!',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTeasers.length,
                          itemBuilder: (context, index) {
                            final teaser = _filteredTeasers[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BrainTeaserDetailPage(teaser: teaser),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                teaser.question,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getDifficultyColor(teaser.difficulty).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getDifficultyColor(teaser.difficulty),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _getDifficultyText(teaser.difficulty),
                                                style: TextStyle(
                                                  color: _getDifficultyColor(teaser.difficulty),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                teaser.category,
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: colorScheme.onSurface.withOpacity(0.4),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
} 