import 'package:flutter/material.dart';
import 'brain_teasers_list.dart';
import 'create_brain_teaser.dart';

class BrainTeasers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Brain Teasers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32),
                
                // Header Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.psychology,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Brain Teasers',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Challenge Your Mind',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Features Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildFeatureCard(
                      context,
                      Icons.list,
                      'Browse Teasers',
                      'Explore our collection of brain teasers',
                      colorScheme.primary,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BrainTeasersListPage()),
                      ),
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.add_circle,
                      'Create New',
                      'Add your own brain teasers',
                      colorScheme.secondary,
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateBrainTeaserPage()),
                        );
                        if (result == true) {
                          // Refresh if a new teaser was created
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => BrainTeasersListPage()),
                          );
                        }
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.shuffle,
                      'Random Challenge',
                      'Get a random brain teaser',
                      Colors.orange,
                      () {
                        // Navigate to list and show random teaser
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BrainTeasersListPage()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.leaderboard,
                      'Track Progress',
                      'Monitor your solving skills',
                      Colors.purple,
                      () {
                        // Navigate to list page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BrainTeasersListPage()),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Quick Start Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BrainTeasersListPage()),
                      );
                    },
                    icon: Icon(Icons.play_arrow),
                    label: Text(
                      'Start Solving',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Info Text
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Brain teasers help improve:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber),
                                SizedBox(height: 8),
                                Text('Critical Thinking', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.psychology, color: Colors.blue),
                                SizedBox(height: 8),
                                Text('Problem Solving', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.emoji_emotions, color: Colors.green),
                                SizedBox(height: 8),
                                Text('Creativity', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}