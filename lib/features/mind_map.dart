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

  void _addNode(MindMapNode parent) {
    final newOffset = Offset(
      parent.offset.dx + Random().nextInt(100) - 50,
      parent.offset.dy + Random().nextInt(100) - 50,
    );

    setState(() {
      _nodes.add(MindMapNode(label: "New Node", offset: newOffset, parent: parent));
    });
  }

  void _editNode(MindMapNode node) async {
    TextEditingController controller = TextEditingController(text: node.label);
    String? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Node"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text("Save")),
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
              painter: MindMapPainter(nodes: _nodes),
            ),
            ..._nodes.map((node) => Positioned(
                  left: node.offset.dx,
                  top: node.offset.dy,
                  child: GestureDetector(
                    onTap: () => _editNode(node),
                    onDoubleTap: () => _addNode(node),
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
                          )
                        ],
                      ),
                      child: Center(child: Text(node.label, textAlign: TextAlign.center)),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

class MindMapNode {
  String label;
  Offset offset;
  MindMapNode? parent;

  MindMapNode({required this.label, required this.offset, this.parent});
}

class MindMapPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  MindMapPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2;

    for (var node in nodes) {
      if (node.parent != null) {
        canvas.drawLine(node.parent!.offset + Offset(50, 25), node.offset + Offset(50, 25), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
