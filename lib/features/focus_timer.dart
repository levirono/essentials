import 'package:flutter/material.dart';
import 'dart:async';

class FocusTimer extends StatefulWidget {
  @override
  _FocusTimerState createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> {
  static const maxSeconds = 1500; // 25 minutes
  int _seconds = maxSeconds;
  Timer? _timer;

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _seconds = maxSeconds;
    });
  }

  String get _formattedTime {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Focus Timer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formattedTime, style: TextStyle(fontSize: 48)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startTimer, child: Text("Start")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _stopTimer, child: Text("Pause")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _resetTimer, child: Text("Reset")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
