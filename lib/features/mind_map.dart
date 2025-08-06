import 'package:flutter/material.dart';
import 'dart:math';
import '../database_helper.dart';
import 'mind_map_list_page.dart';
import 'dart:convert';

class MindMapPage extends StatefulWidget {
  final MindMapModel? initialModel;
  final int? mindMapId;
  const MindMapPage({Key? key, this.initialModel, this.mindMapId})
    : super(key: key);
  @override
  _MindMapPageState createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  late List<MindMapNode> _nodes;
  late List<List<Offset>> _drawings;
  String _title = "Untitled";
  int? _mindMapId;
  // Drawing state
  bool _drawingMode = false;
  List<Offset> _currentLine = [];
  // Undo/redo
  final List<MindMapModel> _undoStack = [];
  final List<MindMapModel> _redoStack = [];
  // Connect mode
  bool _connectMode = false;
  int? _firstConnectIdx;

  void _addNode(int parentIdx) {
    final parent = _nodes[parentIdx];
    final newOffset = Offset(
      parent.offset.dx + Random().nextInt(100) - 50,
      parent.offset.dy + Random().nextInt(100) - 50,
    );
    _pushUndo();
    setState(() {
      _nodes.add(MindMapNode(label: "New Node", offset: newOffset));
      // Connect parent to new node
      _nodes[parentIdx].connections.add(_nodes.length - 1);
      _nodes.last.connections.add(parentIdx);
    });
  }

  void _deleteNode(int idx) {
    if (_nodes.length <= 1) return;
    _pushUndo();
    setState(() {
      // Remove connections to this node
      for (var node in _nodes) {
        node.connections.remove(idx);
        node.connections.removeWhere((c) => c >= _nodes.length - 1);
      }
      _nodes.removeAt(idx);
      // Fix indices in connections
      for (var node in _nodes) {
        node.connections =
            node.connections.map((c) => c > idx ? c - 1 : c).toList();
      }
    });
  }

  void _toggleConnection(int idxA, int idxB) {
    _pushUndo();
    setState(() {
      if (_nodes[idxA].connections.contains(idxB)) {
        _nodes[idxA].connections.remove(idxB);
        _nodes[idxB].connections.remove(idxA);
      } else {
        _nodes[idxA].connections.add(idxB);
        _nodes[idxB].connections.add(idxA);
      }
    });
  }

  void _pushUndo() {
    _undoStack.add(_currentModel());
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_currentModel());
    final prev = _undoStack.removeLast();
    setState(() {
      _title = prev.title;
      _nodes = prev.nodes.map((n) => MindMapNode.fromMap(n.toMap())).toList();
      _drawings = prev.drawings.map((l) => List<Offset>.from(l)).toList();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_currentModel());
    final next = _redoStack.removeLast();
    setState(() {
      _title = next.title;
      _nodes = next.nodes.map((n) => MindMapNode.fromMap(n.toMap())).toList();
      _drawings = next.drawings.map((l) => List<Offset>.from(l)).toList();
    });
  }

  void _editNode(MindMapNode node) async {
    TextEditingController controller = TextEditingController(text: node.label);
    String? result = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Node"),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text("Save"),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      _pushUndo();
      setState(() => node.label = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _editTitle,
          child: Text(
            _title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_drawingMode ? Icons.gesture : Icons.gesture_outlined),
            tooltip: _drawingMode ? 'Drawing Mode On' : 'Drawing Mode Off',
            onPressed: () => setState(() => _drawingMode = !_drawingMode),
          ),
          IconButton(
            icon: Icon(
              _connectMode
                  ? Icons.arrow_right_alt
                  : Icons.arrow_right_alt_outlined,
            ),
            tooltip: _connectMode ? 'Connect Mode On' : 'Connect Mode Off',
            onPressed:
                () => setState(() {
                  _connectMode = !_connectMode;
                  _firstConnectIdx = null;
                }),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMindMap,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MindMapListPage()),
                ),
            tooltip: 'Recent Mind Maps',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNode(0),
        child: const Icon(Icons.add),
        tooltip: 'Add Node',
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (_drawingMode) {
            setState(() {
              _currentLine.add(details.localPosition);
            });
          } else if (_draggingNodeIdx != null) {
            _updateNodeDrag(details.localPosition, details.delta);
          }
        },
        onPanEnd: (details) {
          if (_drawingMode && _currentLine.length > 1) {
            _pushUndo();
            setState(() {
              _drawings.add(List<Offset>.from(_currentLine));
              _currentLine.clear();
            });
          } else if (_draggingNodeIdx != null) {
            _endNodeDrag();
          }
        },
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: MindMapPainter(
                nodes: _nodes,
                drawings: [
                  ..._drawings,
                  if (_drawingMode && _currentLine.isNotEmpty) _currentLine,
                ],
              ),
            ),
            ..._nodes.asMap().entries.map((entry) {
              final idx = entry.key;
              final node = entry.value;
              final isDragging = _draggingNodeIdx == idx;
              return Positioned(
                left: node.offset.dx,
                top: node.offset.dy,
                child: GestureDetector(
                  onTap: () {
                    if (_connectMode) {
                      setState(() {
                        if (_firstConnectIdx == null) {
                          _firstConnectIdx = idx;
                        } else if (_firstConnectIdx != idx) {
                          _toggleConnection(_firstConnectIdx!, idx);
                          _firstConnectIdx = null;
                        }
                      });
                    } else {
                      _editNode(node);
                    }
                  },
                  onDoubleTap: () => _addNode(idx),
                  onLongPressStart: (details) {
                    setState(() {
                      _draggingNodeIdx = idx;
                      _dragStartOffset = details.localPosition - node.offset;
                    });
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isDragging
                              ? Colors.yellow[200]
                              : (_connectMode && _firstConnectIdx == idx
                                  ? Colors.orange[200]
                                  : Colors.green[100]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
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

  // Node drag helpers
  int? _draggingNodeIdx;
  Offset? _dragStartOffset;
  void _updateNodeDrag(Offset pos, Offset delta) {
    if (_draggingNodeIdx != null) {
      setState(() {
        _nodes[_draggingNodeIdx!].offset =
            pos - (_dragStartOffset ?? Offset.zero);
      });
    }
  }

  void _endNodeDrag() {
    if (_draggingNodeIdx != null) {
      _pushUndo();
      setState(() {});
      _draggingNodeIdx = null;
      _dragStartOffset = null;
    }
  }

  void _showNodeMenu(int idx) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Connect/Disconnect to...'),
                onTap: () async {
                  Navigator.pop(context);
                  final otherIdx = await _pickNodeToConnect(idx);
                  if (otherIdx != null && otherIdx != idx) {
                    _toggleConnection(idx, otherIdx);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Node'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNode(idx);
                },
              ),
            ],
          ),
    );
  }

  Future<int?> _pickNodeToConnect(int fromIdx) async {
    return showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select node to connect/disconnect'),
            children:
                _nodes
                    .asMap()
                    .entries
                    .where((e) => e.key != fromIdx)
                    .map(
                      (e) => SimpleDialogOption(
                        child: Text(e.value.label),
                        onPressed: () => Navigator.pop(context, e.key),
                      ),
                    )
                    .toList(),
          ),
    );
  }

  void _editTitle() async {
    TextEditingController controller = TextEditingController(text: _title);
    String? result = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Mind Map Title"),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text("Save"),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _title = result);
    }
  }

  void _saveMindMap() async {
    final model = _currentModel();
    if (_mindMapId == null) {
      final id = await DatabaseHelper().insertMindMap(
        model.title,
        model.toMap(),
      );
      setState(() => _mindMapId = id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mind map saved.')));
    } else {
      await DatabaseHelper().updateMindMap(
        _mindMapId!,
        model.title,
        model.toMap(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mind map updated.')));
    }
  }

  MindMapModel _currentModel() =>
      MindMapModel(title: _title, nodes: _nodes, drawings: _drawings);

  @override
  void initState() {
    super.initState();
    if (widget.initialModel != null) {
      _title = widget.initialModel!.title;
      _nodes =
          widget.initialModel!.nodes
              .map((n) => MindMapNode.fromMap(n.toMap()))
              .toList();
      _drawings =
          widget.initialModel!.drawings
              .map((l) => List<Offset>.from(l))
              .toList();
      _mindMapId = widget.mindMapId;
    } else {
      _title = "Central Idea";
      _nodes = [
        MindMapNode(label: "Central Idea", offset: const Offset(150, 300)),
      ];
      _drawings = [];
      _mindMapId = null;
    }
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

    // Draw arrows for connections
    void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
      // Draw main line
      canvas.drawLine(from, to, paint);
      // Draw arrowhead
      const double arrowSize = 16;
      final angle = (to - from).direction;
      final arrowP1 = to - Offset.fromDirection(angle - 0.4, arrowSize);
      final arrowP2 = to - Offset.fromDirection(angle + 0.4, arrowSize);
      final path =
          Path()
            ..moveTo(to.dx, to.dy)
            ..lineTo(arrowP1.dx, arrowP1.dy)
            ..moveTo(to.dx, to.dy)
            ..lineTo(arrowP2.dx, arrowP2.dy);
      canvas.drawPath(path, paint);
    }

    final arrowPaint =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 3;
    for (int i = 0; i < nodes.length; i++) {
      for (final conn in nodes[i].connections) {
        if (conn >= 0 && conn < nodes.length && conn != i && i < conn) {
          final from = nodes[i].offset + const Offset(50, 25);
          final to = nodes[conn].offset + const Offset(50, 25);
          _drawArrow(canvas, from, to, arrowPaint);
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
