import 'package:flutter/material.dart';
import 'dart:math';

class MindMapPage extends StatefulWidget {
  @override
  _MindMapPageState createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  final List<MindMapNode> _nodes = [
    MindMapNode(label: "Central Idea", offset: Offset(150, 300)),
  ];
  final List<List<Offset>> _drawings = [];

  void _addNode(int parentIdx) {
    final parent = _nodes[parentIdx];
    final newOffset = Offset(
      parent.offset.dx + Random().nextInt(100) - 50,
      parent.offset.dy + Random().nextInt(100) - 50,
    );
    setState(() {
      _nodes.add(MindMapNode(label: "New Node", offset: newOffset));
      // Connect parent to new node
      _nodes[parentIdx].connections.add(_nodes.length - 1);
      _nodes.last.connections.add(parentIdx);
    });
  }

  void _editNode(MindMapNode node) async {
    TextEditingController controller = TextEditingController(text: node.label);
    String? result = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Node"),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text("Save"),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => node.label = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mind Map")),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            for (var node in _nodes) {
              if ((details.localPosition - node.offset).distance < 40) {
                node.offset += details.delta;
              }
            }
          });
        },
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: MindMapPainter(nodes: _nodes, drawings: _drawings),
            ),
            ..._nodes.asMap().entries.map((entry) {
              final idx = entry.key;
              final node = entry.value;
              return Positioned(
                left: node.offset.dx,
                top: node.offset.dy,
                child: GestureDetector(
                  onTap: () => _editNode(node),
                  onDoubleTap: () => _addNode(idx),
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(node.label, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MindMapNode {
  String label;
  Offset offset;
  List<int> connections; // store indices of connected nodes

  MindMapNode({
    required this.label,
    required this.offset,
    List<int>? connections,
  }) : connections = connections ?? [];

  Map<String, dynamic> toMap() => {
    'label': label,
    'offset': {'dx': offset.dx, 'dy': offset.dy},
    'connections': connections,
  };

  factory MindMapNode.fromMap(Map<String, dynamic> map) => MindMapNode(
    label: map['label'],
    offset: Offset(map['offset']['dx'], map['offset']['dy']),
    connections: List<int>.from(map['connections'] ?? []),
  );
}

class MindMapModel {
  String title;
  List<MindMapNode> nodes;
  List<List<Offset>> drawings; // freehand lines

  MindMapModel({
    required this.title,
    required this.nodes,
    List<List<Offset>>? drawings,
  }) : drawings = drawings ?? [];

  Map<String, dynamic> toMap() => {
    'title': title,
    'nodes': nodes.map((n) => n.toMap()).toList(),
    'drawings':
        drawings
            .map(
              (line) => line.map((pt) => {'dx': pt.dx, 'dy': pt.dy}).toList(),
            )
            .toList(),
  };

  factory MindMapModel.fromMap(Map<String, dynamic> map) => MindMapModel(
    title: map['title'],
    nodes: (map['nodes'] as List).map((n) => MindMapNode.fromMap(n)).toList(),
    drawings:
        (map['drawings'] as List?)
            ?.map<List<Offset>>(
              (line) =>
                  (line as List)
                      .map((pt) => Offset(pt['dx'], pt['dy']))
                      .toList(),
            )
            .toList() ??
        [],
  );
}

class MindMapPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final List<List<Offset>> drawings;
  MindMapPainter({required this.nodes, required this.drawings});

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 2;
    final drawingPaint =
        Paint()
          ..color = Colors.blueAccent.withOpacity(0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Draw connections
    for (int i = 0; i < nodes.length; i++) {
      for (final conn in nodes[i].connections) {
        if (conn >= 0 && conn < nodes.length && conn != i) {
          canvas.drawLine(
            nodes[i].offset + Offset(50, 25),
            nodes[conn].offset + Offset(50, 25),
            nodePaint,
          );
        }
      }
    }

    // Draw freehand drawings
    for (final line in drawings) {
      if (line.length > 1) {
        final path = Path()..moveTo(line[0].dx, line[0].dy);
        for (int i = 1; i < line.length; i++) {
          path.lineTo(line[i].dx, line[i].dy);
        }
        canvas.drawPath(path, drawingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
