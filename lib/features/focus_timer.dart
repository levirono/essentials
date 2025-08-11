import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusTimerPage extends StatefulWidget {
  @override
  _FocusTimerPageState createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  // Pomodoro settings
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _cyclesBeforeLongBreak = 4;
  int _longBreakMinutes = 15;

  Duration _duration = Duration(minutes: 25); // current session duration
  Duration _remaining = Duration(minutes: 25);
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusSession = true;
  int _completedCycles = 0;
  int _totalFocusSessions = 0;

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds == 0) {
        _onSessionComplete();
      } else {
        setState(() {
          _remaining = _remaining - Duration(seconds: 1);
        });
      }
    });

    setState(() => _isRunning = true);
  }

  void _onSessionComplete() async {
    _stopTimer(reset: false);
    // Play a notification sound (system beep)
    SystemSound.play(SystemSoundType.alert);

    if (_isFocusSession) {
      _totalFocusSessions++;
      _completedCycles++;
    }

    String title = _isFocusSession ? "Focus Session Complete 🎉" : "Break Over!";
    String content = _isFocusSession
        ? (_completedCycles % _cyclesBeforeLongBreak == 0
            ? "Time for a long break!"
            : "Take a short break!")
        : "Ready to focus again?";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );

    // Auto-switch between focus and break sessions
    if (_isFocusSession) {
      if (_completedCycles % _cyclesBeforeLongBreak == 0) {
        _startBreak(long: true);
      } else {
        _startBreak();
      }
    } else {
      _startFocus();
    }
  }

  void _startFocus() {
    setState(() {
      _isFocusSession = true;
      _duration = Duration(minutes: _focusMinutes);
      _remaining = _duration;
    });
    _startTimer();
  }

  void _startBreak({bool long = false}) {
    setState(() {
      _isFocusSession = false;
      _duration = Duration(minutes: long ? _longBreakMinutes : _breakMinutes);
      _remaining = _duration;
    });
    _startTimer();
  }

  void _stopTimer({bool reset = true}) {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      if (reset) {
        _remaining = _duration;
      }
    });
  }

  void _setDuration(int minutes) {
    _stopTimer();
    setState(() {
      _focusMinutes = minutes;
      _duration = Duration(minutes: minutes);
      _remaining = _duration;
      _isFocusSession = true;
      _completedCycles = 0;
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
            SizedBox(height: 24),
            Text(
              _isFocusSession ? "Focus" : (_completedCycles % _cyclesBeforeLongBreak == 0 && !_isFocusSession ? "Long Break" : "Break"),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: _isFocusSession ? Colors.green : Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              _formatDuration(_remaining),
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Completed Focus Sessions: $_totalFocusSessions",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            LinearProgressIndicator(
              value: 1 - (_remaining.inSeconds / _duration.inSeconds),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_isFocusSession ? Colors.green : Colors.blue),
            ),
            SizedBox(height: 32),
            Wrap(
              spacing: 16,
              children: [15, 25, 45].map((min) {
                return ElevatedButton(
                  onPressed: () => _setDuration(min),
                  child: Text("$min min"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _focusMinutes == min ? Colors.green : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 32),
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
                        label: Text(_isFocusSession ? "Start Focus" : "Start Break"),
                        onPressed: _isFocusSession ? _startFocus : _startBreak,
                      ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Reset"),
                  onPressed: () {
                    _stopTimer();
                    setState(() {
                      _isFocusSession = true;
                      _duration = Duration(minutes: _focusMinutes);
                      _remaining = _duration;
                      _completedCycles = 0;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            ListTile(
              title: Text("Pomodoro Settings"),
              subtitle: Text("Focus: $_focusMinutes min, Break: $_breakMinutes min, Long Break: $_longBreakMinutes min every $_cyclesBeforeLongBreak cycles"),
              trailing: IconButton(
                icon: Icon(Icons.settings),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) {
                      int focus = _focusMinutes;
                      int brk = _breakMinutes;
                      int longBrk = _longBreakMinutes;
                      int cycles = _cyclesBeforeLongBreak;
                      return AlertDialog(
                        title: Text("Pomodoro Settings"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text("Focus (min): "),
                                Expanded(
                                  child: Slider(
                                    value: focus.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    label: focus.toString(),
                                    onChanged: (v) {
                                      focus = v.round();
                                    },
                                  ),
                                ),
                                Text(focus.toString()),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Break (min): "),
                                Expanded(
                                  child: Slider(
                                    value: brk.toDouble(),
                                    min: 1,
                                    max: 30,
                                    divisions: 29,
                                    label: brk.toString(),
                                    onChanged: (v) {
                                      brk = v.round();
                                    },
                                  ),
                                ),
                                Text(brk.toString()),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Long Break (min): "),
                                Expanded(
                                  child: Slider(
                                    value: longBrk.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    label: longBrk.toString(),
                                    onChanged: (v) {
                                      longBrk = v.round();
                                    },
                                  ),
                                ),
                                Text(longBrk.toString()),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Cycles: "),
                                Expanded(
                                  child: Slider(
                                    value: cycles.toDouble(),
                                    min: 2,
                                    max: 8,
                                    divisions: 6,
                                    label: cycles.toString(),
                                    onChanged: (v) {
                                      cycles = v.round();
                                    },
                                  ),
                                ),
                                Text(cycles.toString()),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _focusMinutes = focus;
                                _breakMinutes = brk;
                                _longBreakMinutes = longBrk;
                                _cyclesBeforeLongBreak = cycles;
                                _duration = Duration(minutes: _isFocusSession ? _focusMinutes : _breakMinutes);
                                _remaining = _duration;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text("Save"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
