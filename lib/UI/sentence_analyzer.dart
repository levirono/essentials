import 'package:flutter/material.dart';
import 'dart:ui'; // Added for ImageFilter
import 'dart:math';
import '../database_helper.dart';

class SentenceAnalyzerPage extends StatefulWidget {
  @override
  _SentenceAnalyzerPageState createState() => _SentenceAnalyzerPageState();
}

class _SentenceAnalyzerPageState extends State<SentenceAnalyzerPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic> _analysisResults = {};
  List<AnalyzedSentence> _recentAnalyses = [];
  bool _isAnalyzing = false;
  bool _showRecentAnalyses = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRecentAnalyses();
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAnalyses() async {
    try {
      final analyses = await _databaseHelper.getRecentAnalyzedSentences(limit: 10);
      setState(() {
        _recentAnalyses = analyses;
      });
    } catch (e) {
      print('Error loading recent analyses: $e');
    }
  }

  Future<void> _saveAnalysis(String text, Map<String, dynamic> results) async {
    try {
      final sentence = AnalyzedSentence(
        text: text,
        analysisResults: results,
        analyzedAt: DateTime.now(),
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      );
      
      await _databaseHelper.insertAnalyzedSentence(sentence);
      await _loadRecentAnalyses();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _analyzeSentence() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter some text to analyze'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Simulate processing time for better UX
    await Future.delayed(Duration(milliseconds: 800));

    final text = _textController.text.trim();
    final results = _performAnalysis(text);

    setState(() {
      _analysisResults = results;
      _isAnalyzing = false;
    });

    _animationController.forward();
    
    // Auto-save the analysis
    await _saveAnalysis(text, results);
  }

  Map<String, dynamic> _performAnalysis(String text) {
    // Word Analysis
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));
    final uniqueWords = words.toSet().toList();
    final wordFrequency = <String, int>{};

    for (String word in words) {
      if (word.isNotEmpty) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }

    // Character Analysis
    final characters = text.replaceAll(' ', '');
    final vowels =
        text
            .toLowerCase()
            .split('')
            .where((char) => 'aeiou'.contains(char))
            .length;
    final consonants = characters.length - vowels;

    // Sentence Analysis
    final sentences =
        text
            .split(RegExp(r'[.!?]+'))
            .where((s) => s.trim().isNotEmpty)
            .toList();

    // Average word length
    final totalWordLength = words
        .where((w) => w.isNotEmpty)
        .fold(0, (sum, word) => sum + word.length);
    final averageWordLength =
        words.isNotEmpty ? totalWordLength / words.length : 0;

    // Reading time estimation (average 200 words per minute)
    final estimatedReadingTime = (words.length / 200 * 60).round();

    // Text complexity score (simple heuristic)
    final complexityScore = _calculateComplexityScore(text, words, sentences);

    // Most frequent words (top 5)
    final sortedWords =
        wordFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topWords = sortedWords.take(5).toList();

    // Enhanced analysis features
    final sentimentScore = _analyzeSentiment(text);
    final readabilityScore = _calculateReadabilityScore(words, sentences);
    final languagePatterns = _analyzeLanguagePatterns(text);
    final paragraphCount = _countParagraphs(text);
    final averageSentenceLength = sentences.isNotEmpty ? words.length / sentences.length : 0;
    final lexicalDiversity = uniqueWords.length / words.length;
    final keywordDensity = _calculateKeywordDensity(wordFrequency, words.length);

    return {
      'wordCount': words.where((w) => w.isNotEmpty).length,
      'uniqueWords': uniqueWords.length,
      'characterCount': text.length,
      'characterCountNoSpaces': characters.length,
      'vowelCount': vowels,
      'consonantCount': consonants,
      'sentenceCount': sentences.length,
      'paragraphCount': paragraphCount,
      'averageWordLength': averageWordLength,
      'averageSentenceLength': averageSentenceLength,
      'readingTimeSeconds': estimatedReadingTime,
      'complexityScore': complexityScore,
      'sentimentScore': sentimentScore,
      'readabilityScore': readabilityScore,
      'lexicalDiversity': lexicalDiversity,
      'languagePatterns': languagePatterns,
      'keywordDensity': keywordDensity,
      'topWords': topWords,
      'wordFrequency': wordFrequency,
    };
  }

  double _calculateComplexityScore(
    String text,
    List<String> words,
    List<String> sentences,
  ) {
    // Simple complexity heuristic based on:
    // - Average word length
    // - Average sentence length
    // - Punctuation density

    final avgWordLength =
        words.isNotEmpty
            ? words
                    .where((w) => w.isNotEmpty)
                    .fold(0, (sum, word) => sum + word.length) /
                words.length
            : 0;

    final avgSentenceLength =
        sentences.isNotEmpty ? words.length / sentences.length : 0;

    final punctuationCount =
        text.split('').where((char) => '.,!?;:'.contains(char)).length;
    final punctuationDensity =
        text.isNotEmpty ? punctuationCount / text.length : 0;

    // Normalize and combine factors (scale 1-10)
    final wordLengthScore = (avgWordLength / 8).clamp(0.0, 1.0) * 3;
    final sentenceLengthScore = (avgSentenceLength / 20).clamp(0.0, 1.0) * 4;
    final punctuationScore = (punctuationDensity * 20).clamp(0.0, 1.0) * 3;

    return (wordLengthScore + sentenceLengthScore + punctuationScore).clamp(
      1.0,
      10.0,
    );
  }

  Map<String, dynamic> _analyzeSentiment(String text) {
    // Simple sentiment analysis based on word lists
    final positiveWords = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'love', 'like', 'happy', 'joy', 'beautiful', 'perfect', 'awesome', 'brilliant', 'outstanding'];
    final negativeWords = ['bad', 'terrible', 'awful', 'horrible', 'hate', 'dislike', 'sad', 'angry', 'disappointed', 'frustrated', 'annoying', 'disgusting', 'worst', 'pathetic', 'useless'];
    
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (String word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    final totalSentimentWords = positiveCount + negativeCount;
    double sentimentScore = 0.5; // Neutral
    String sentiment = 'Neutral';
    
    if (totalSentimentWords > 0) {
      sentimentScore = positiveCount / totalSentimentWords;
      if (sentimentScore > 0.6) {
        sentiment = 'Positive';
      } else if (sentimentScore < 0.4) {
        sentiment = 'Negative';
      }
    }
    
    return {
      'score': sentimentScore,
      'label': sentiment,
      'positiveWords': positiveCount,
      'negativeWords': negativeCount,
    };
  }

  double _calculateReadabilityScore(List<String> words, List<String> sentences) {
    // Simplified Flesch Reading Ease Score
    if (words.isEmpty || sentences.isEmpty) return 0.0;
    
    final avgSentenceLength = words.length / sentences.length;
    final avgSyllables = words.map(_countSyllables).reduce((a, b) => a + b) / words.length;
    
    final score = 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllables);
    return score.clamp(0.0, 100.0);
  }

  int _countSyllables(String word) {
    // Simple syllable counting heuristic
    final vowels = 'aeiouAEIOU';
    int count = 0;
    bool previousWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      bool isVowel = vowels.contains(word[i]);
      if (isVowel && !previousWasVowel) {
        count++;
      }
      previousWasVowel = isVowel;
    }
    
    // Handle silent 'e'
    if (word.endsWith('e') && count > 1) {
      count--;
    }
    
    return max(1, count); // Every word has at least one syllable
  }

  Map<String, dynamic> _analyzeLanguagePatterns(String text) {
    final questionMarks = text.split('?').length - 1;
    final exclamationMarks = text.split('!').length - 1;
    final periods = text.split('.').length - 1;
    final commas = text.split(',').length - 1;
    final semicolons = text.split(';').length - 1;
    final colons = text.split(':').length - 1;
    
    // Detect writing style patterns
    final hasQuestions = questionMarks > 0;
    final hasExclamations = exclamationMarks > 0;
    final isDialogue = text.contains('"') || text.contains("'");
    final hasNumbers = RegExp(r'\d').hasMatch(text);
    final hasCapitalWords = RegExp(r'\b[A-Z]{2,}\b').hasMatch(text);
    
    return {
      'questionMarks': questionMarks,
      'exclamationMarks': exclamationMarks,
      'periods': periods,
      'commas': commas,
      'semicolons': semicolons,
      'colons': colons,
      'hasQuestions': hasQuestions,
      'hasExclamations': hasExclamations,
      'isDialogue': isDialogue,
      'hasNumbers': hasNumbers,
      'hasCapitalWords': hasCapitalWords,
    };
  }

  int _countParagraphs(String text) {
    return text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
  }

  Map<String, double> _calculateKeywordDensity(Map<String, int> wordFrequency, int totalWords) {
    final keywords = <String, double>{};
    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedWords.take(10)) {
      if (entry.key.length > 3) { // Only consider words longer than 3 characters
        keywords[entry.key] = (entry.value / totalWords) * 100;
      }
    }
    
    return keywords;
  }

  void _clearText() {
    _textController.clear();
    setState(() {
      _analysisResults = {};
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.7),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.secondary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    'Sentence Analyzer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
                  ),
                  centerTitle: true,
                  iconTheme: IconThemeData(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.7),
              colorScheme.secondary.withOpacity(0.7),
              colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input Section
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Text to Analyze',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _textController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Type or paste your text here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isAnalyzing ? null : _analyzeSentence,
                                icon:
                                    _isAnalyzing
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Icon(Icons.analytics),
                                label: Text(
                                  _isAnalyzing
                                      ? 'Analyzing...'
                                      : 'Analyze Text',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _clearText,
                              icon: Icon(Icons.clear),
                              label: Text('Clear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Results Section
                if (_analysisResults.isNotEmpty)
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildBasicStatsCard(),
                            SizedBox(height: 12),
                            _buildDetailedStatsCard(),
                            SizedBox(height: 12),
                            _buildWordFrequencyCard(),
                          ],
                        ),
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

  Widget _buildBasicStatsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Statistics',
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
                  child: _buildStatItem(
                    'Words',
                    _analysisResults['wordCount'].toString(),
                    Icons.text_fields,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Characters',
                    _analysisResults['characterCount'].toString(),
                    Icons.font_download,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sentences',
                    _analysisResults['sentenceCount'].toString(),
                    Icons.format_list_numbered,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Reading Time',
                    '${_analysisResults['readingTimeSeconds']}s',
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              'Unique Words',
              _analysisResults['uniqueWords'].toString(),
            ),
            _buildDetailRow(
              'Vowels',
              _analysisResults['vowelCount'].toString(),
            ),
            _buildDetailRow(
              'Consonants',
              _analysisResults['consonantCount'].toString(),
            ),
            _buildDetailRow(
              'Avg Word Length',
              '${_analysisResults['averageWordLength'].toStringAsFixed(1)} chars',
            ),
            _buildDetailRow(
              'Complexity Score',
              '${_analysisResults['complexityScore'].toStringAsFixed(1)}/10',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordFrequencyCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final topWords =
        _analysisResults['topWords'] as List<MapEntry<String, int>>;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Frequent Words',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            ...topWords
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.key,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: LinearProgressIndicator(
                            value: entry.value / topWords.first.value,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
