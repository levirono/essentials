import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database_helper.dart';
import 'focus_timer_history.dart';

class FocusTimerPage extends StatefulWidget {
  @override
  _FocusTimerPageState createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Timer state
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFocusSession = true;
  int _completedCycles = 0;
  int _totalFocusSessions = 0;
  
  // Current session
  Duration _duration = Duration(minutes: 25);
  Duration _remaining = Duration(minutes: 25);
  DateTime? _sessionStartTime;
  FocusSession? _currentSession;
  
  // Settings
  FocusTimerSettings? _settings;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  // Manual time input
  final TextEditingController _manualTimeController = TextEditingController();
  bool _showManualTimeInput = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await _dbHelper.insertDefaultFocusTimerSettings();
      final settings = await _dbHelper.getFocusTimerSettings();
      setState(() {
        _settings = settings;
        _duration = Duration(minutes: settings?.focusMinutes ?? 25);
        _remaining = _duration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  void _startTimer() {
    if (_timer != null) return;

    _sessionStartTime = DateTime.now();
    _currentSession = FocusSession(
      startTime: _sessionStartTime!,
      duration: _duration,
      sessionType: _isFocusSession ? 'focus' : 'break',
      createdAt: DateTime.now(),
    );

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds == 0) {
        _onSessionComplete();
      } else {
        setState(() {
          _remaining = _remaining - Duration(seconds: 1);
        });
        _progressController.forward();
      }
    });

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    
    _pulseController.repeat();
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isPaused = true;
    });
    _pulseController.stop();
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopTimer({bool reset = true}) {
    _timer?.cancel();
    _timer = null;
    _pulseController.stop();
    
    if (_currentSession != null && _sessionStartTime != null) {
      // Save incomplete session
      _currentSession!.endTime = DateTime.now();
      _dbHelper.insertFocusSession(_currentSession!);
    }
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _currentSession = null;
      _sessionStartTime = null;
      if (reset) {
        _remaining = _duration;
      }
    });
  }

  void _onSessionComplete() async {
    _stopTimer(reset: false);
    
    // Save completed session
    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      _currentSession!.isCompleted = true;
      await _dbHelper.insertFocusSession(_currentSession!);
    }

    // Play notification sound
    SystemSound.play(SystemSoundType.alert);

    if (_isFocusSession) {
      _totalFocusSessions++;
      _completedCycles++;
    }

    String title = _isFocusSession ? "Focus Session Complete! 🎉" : "Break Over!";
    String content = _isFocusSession
        ? (_completedCycles % (_settings?.cyclesBeforeLongBreak ?? 4) == 0
            ? "Time for a long break!"
            : "Take a short break!")
        : "Ready to focus again?";

    // Show completion dialog with optional notes
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Session Notes (Optional)',
                hintText: 'How did this session go?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                if (_currentSession != null) {
                  _currentSession!.notes = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Skip"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Update session with notes if any
              if (_currentSession != null && _currentSession!.notes != null) {
                _dbHelper.updateFocusSession(_currentSession!);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );

    // Auto-switch between focus and break sessions
    if (_isFocusSession) {
      if (_completedCycles % (_settings?.cyclesBeforeLongBreak ?? 4) == 0) {
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
      _duration = Duration(minutes: _settings?.focusMinutes ?? 25);
      _remaining = _duration;
    });
    _startTimer();
  }

  void _startBreak({bool long = false}) {
    setState(() {
      _isFocusSession = false;
      _duration = Duration(minutes: long ? (_settings?.longBreakMinutes ?? 15) : (_settings?.breakMinutes ?? 5));
      _remaining = _duration;
    });
    _startTimer();
  }

  void _setCustomDuration(int minutes) {
    _stopTimer();
    setState(() {
      _duration = Duration(minutes: minutes);
      _remaining = _duration;
      _isFocusSession = true;
      _completedCycles = 0;
    });
  }

  void _showManualTimeDialog() {
    _manualTimeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Custom Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter time in minutes:'),
            SizedBox(height: 16),
            TextField(
              controller: _manualTimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Minutes',
                hintText: 'e.g., 45',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(_manualTimeController.text);
              if (minutes != null && minutes > 0) {
                _setCustomDuration(minutes);
                Navigator.of(context).pop();
              }
            },
            child: Text('Set'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    
    if (d.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _stopTimer();
    _progressController.dispose();
    _pulseController.dispose();
    _manualTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Scaffold(body: FocusTimerHistoryPage())),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Session Type Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isFocusSession ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFocusSession ? Colors.green : Colors.blue,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isFocusSession ? Icons.psychology : Icons.coffee,
                    size: 48,
                    color: _isFocusSession ? Colors.green : Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFocusSession ? "Focus Session" : "Break Time",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isFocusSession ? Colors.green : Colors.blue,
                    ),
                  ),
                  if (!_isFocusSession && _completedCycles % (_settings?.cyclesBeforeLongBreak ?? 4) == 0)
                    Text(
                      "Long Break",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Timer Display
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Progress Ring
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1 - (_remaining.inSeconds / _duration.inSeconds),
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _isFocusSession ? Colors.green : Colors.blue,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isRunning ? 1.0 + (0.1 * _pulseController.value) : 1.0,
                              child: Text(
                                _formatDuration(_remaining),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _isFocusSession ? Colors.green : Colors.blue,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Session Info
                  Text(
                    "Session ${_completedCycles + 1}",
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "Total Focus Sessions: $_totalFocusSessions",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Quick Time Presets
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Presets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [15, 25, 45, 60].map((min) {
                        final isSelected = _duration.inMinutes == min;
                        return ElevatedButton(
                          onPressed: () => _setCustomDuration(min),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? colorScheme.primary : colorScheme.surface,
                            foregroundColor: isSelected ? Colors.white : colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text("$min min"),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showManualTimeDialog,
                        icon: Icon(Icons.edit),
                        label: Text('Custom Time'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.secondary,
                          side: BorderSide(color: colorScheme.secondary),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: _isRunning
                      ? _isPaused
                          ? ElevatedButton.icon(
                              icon: Icon(Icons.play_arrow),
                              label: Text("Resume"),
                              onPressed: _resumeTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: Icon(Icons.pause),
                              label: Text("Pause"),
                              onPressed: _pauseTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                      : ElevatedButton.icon(
                          icon: Icon(Icons.play_arrow),
                          label: Text(_isFocusSession ? "Start Focus" : "Start Break"),
                          onPressed: _isFocusSession ? _startFocus : _startBreak,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text("Reset"),
                    onPressed: () {
                      _stopTimer();
                      setState(() {
                        _isFocusSession = true;
                        _duration = Duration(minutes: _settings?.focusMinutes ?? 25);
                        _remaining = _duration;
                        _completedCycles = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualTimeDialog,
        icon: Icon(Icons.add),
        label: Text('Quick Start'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showSettingsDialog() async {
    if (_settings == null) return;
    
    int focus = _settings!.focusMinutes;
    int brk = _settings!.breakMinutes;
    int longBrk = _settings!.longBreakMinutes;
    int cycles = _settings!.cyclesBeforeLongBreak;
    bool autoStartBreaks = _settings!.autoStartBreaks;
    bool autoStartFocus = _settings!.autoStartFocus;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Focus Timer Settings"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingRow(
                    "Focus (min):",
                    focus.toDouble(),
                    5.0,
                    120.0,
                    (value) => setDialogState(() => focus = value.round()),
                    focus.toString(),
                  ),
                  _buildSettingRow(
                    "Break (min):",
                    brk.toDouble(),
                    1.0,
                    60.0,
                    (value) => setDialogState(() => brk = value.round()),
                    brk.toString(),
                  ),
                  _buildSettingRow(
                    "Long Break (min):",
                    longBrk.toDouble(),
                    5.0,
                    120.0,
                    (value) => setDialogState(() => longBrk = value.round()),
                    longBrk.toString(),
                  ),
                  _buildSettingRow(
                    "Cycles:",
                    cycles.toDouble(),
                    2.0,
                    10.0,
                    (value) => setDialogState(() => cycles = value.round()),
                    cycles.toString(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: autoStartBreaks,
                        onChanged: (value) => setDialogState(() => autoStartBreaks = value!),
                      ),
                      Text("Auto-start breaks"),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: autoStartFocus,
                        onChanged: (value) => setDialogState(() => autoStartFocus = value!),
                      ),
                      Text("Auto-start focus sessions"),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newSettings = FocusTimerSettings(
                    id: _settings!.id,
                    focusMinutes: focus,
                    breakMinutes: brk,
                    longBreakMinutes: longBrk,
                    cyclesBeforeLongBreak: cycles,
                    autoStartBreaks: autoStartBreaks,
                    autoStartFocus: autoStartFocus,
                    updatedAt: DateTime.now(),
                  );
                  
                  await _dbHelper.insertOrUpdateFocusTimerSettings(newSettings);
                  setState(() {
                    _settings = newSettings;
                    if (!_isRunning) {
                      _duration = Duration(minutes: focus);
                      _remaining = _duration;
                    }
                  });
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings saved successfully!')),
                  );
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(
            flex: 2,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 1).round(),
              label: displayValue,
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 16),
          Text(displayValue, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showStatsDialog() async {
    try {
      final stats = await _dbHelper.getFocusTimerStats();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Focus Timer Statistics"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow("Total Focus Time", "${stats['totalFocusMinutes']} minutes"),
                _buildStatRow("Completed Sessions", "${stats['completedSessions']}"),
                _buildStatRow("Total Sessions", "${stats['totalSessions']}"),
                _buildStatRow("Average Session", "${stats['averageSessionLength'].toStringAsFixed(1)} minutes"),
                SizedBox(height: 16),
                Text(
                  "Last 7 Days:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...stats['dailyStats'].entries.map((entry) {
                  final date = DateTime.parse(entry.key);
                  final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                  return _buildStatRow(dayName, "${entry.value} min");
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
