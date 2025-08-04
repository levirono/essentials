import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'mind_map.dart';

class MindMapListPage extends StatefulWidget {
  const MindMapListPage({Key? key}) : super(key: key);

  @override
  State<MindMapListPage> createState() => _MindMapListPageState();
}

class _MindMapListPageState extends State<MindMapListPage> {
  List<Map<String, dynamic>> _mindMaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMindMaps();
  }

  Future<void> _loadMindMaps() async {
    final maps = await DatabaseHelper().getMindMaps();
    setState(() {
      _mindMaps = maps;
      _loading = false;
    });
  }

  void _openMindMap(Map<String, dynamic> map) async {
    // TODO: Implement navigation to MindMapPage with loaded data
    // Navigator.push(context, ...);
  }

  void _deleteMindMap(int id) async {
    await DatabaseHelper().deleteMindMap(id);
    _loadMindMaps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mind Maps')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _mindMaps.isEmpty
              ? const Center(child: Text('No mind maps found.'))
              : ListView.separated(
                itemCount: _mindMaps.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final map = _mindMaps[index];
                  return ListTile(
                    title: Text(map['title'] ?? 'Untitled'),
                    subtitle: Text('Updated: ' + (map['updatedAt'] ?? '')),
                    onTap: () => _openMindMap(map),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMindMap(map['id']),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create new mind map
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Mind Map',
      ),
    );
  }
}
