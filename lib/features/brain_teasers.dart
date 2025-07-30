import 'package:flutter/material.dart';
import 'dart:math';

class BrainTeasers extends StatefulWidget {
  @override
  _BrainTeasersState createState() => _BrainTeasersState();
}

class _BrainTeasersState extends State<BrainTeasers> {
  final _rand = Random();
  int _a = 0, _b = 0, _userAnswer = 0;
  String _feedback = '';
  final _controller = TextEditingController();

  void _generateQuestion() {
    _a = _rand.nextInt(20);
    _b = _rand.nextInt(20);
    _controller.clear();
    _feedback = '';
    setState(() {});
  }

  void _checkAnswer() {
    if (int.tryParse(_controller.text) == _a + _b) {
      _feedback = 'Correct! 🎉';
    } else {
      _feedback = 'Try again 😬';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Brain Teasers")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("What's $_a + $_b?", style: TextStyle(fontSize: 24)),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Your answer'),
            ),
            Row(
              children: [
                ElevatedButton(onPressed: _checkAnswer, child: Text("Submit")),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _generateQuestion,
                  child: Text("Next"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(_feedback, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
