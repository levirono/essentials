import 'dart:async';
import 'package:flutter/material.dart';

class FocusTimerPage extends StatefulWidget {
  @override
  _FocusTimerPageState createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  Duration _duration = Duration(minutes: 25); // default Pomodoro session
  Duration _remaining = Duration(minutes: 25);
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds == 0) {
        _stopTimer(reset: false);
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text("Focus Session Complete 🎉"),
                content: Text("Take a break!"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        setState(() {
          _remaining = _remaining - Duration(seconds: 1);
        });
      }
    });

    setState(() => _isRunning = true);
  }

  void _stopTimer({bool reset = true}) {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      if (reset) _remaining = _duration;
    });
  }

  void _setDuration(int minutes) {
    _stopTimer();
    setState(() {
      _duration = Duration(minutes: minutes);
      _remaining = _duration;
    });
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Focus Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text(
              _formatDuration(_remaining),
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            LinearProgressIndicator(
              value: 1 - (_remaining.inSeconds / _duration.inSeconds),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(Colors.green),
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 16,
              children:
                  [15, 25, 45].map((min) {
                    return ElevatedButton(
                      onPressed: () => _setDuration(min),
                      child: Text("$min min"),
                    );
                  }).toList(),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isRunning
                    ? ElevatedButton.icon(
                      icon: Icon(Icons.pause),
                      label: Text("Pause"),
                      onPressed: _stopTimer,
                    )
                    : ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: Text("Start"),
                      onPressed: _startTimer,
                    ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Reset"),
                  onPressed: () => _stopTimer(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
