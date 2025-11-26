import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/pomodoro_session.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class PomodoroScreen extends StatefulWidget {
  final Todo? linkedTodo;

  const PomodoroScreen({super.key, this.linkedTodo});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;
  int _timeRemaining = 0; // in seconds
  int _completedSessions = 0;
  int _workDuration = 25;
  int _breakDuration = 5;
  int _longBreakDuration = 15;
  int _sessionsBeforeLongBreak = 4;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final userProvider = context.read<UserProvider>();
    setState(() {
      _workDuration = userProvider.settings?.pomodoroWorkDuration ?? 25;
      _breakDuration = userProvider.settings?.pomodoroBreakDuration ?? 5;
      _longBreakDuration = userProvider.settings?.pomodoroLongBreakDuration ?? 15;
      _sessionsBeforeLongBreak = userProvider.settings?.pomodoroSessionsBeforeLongBreak ?? 4;
      _timeRemaining = _workDuration * 60;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startWork() {
    setState(() {
      _state = PomodoroState.working;
      _timeRemaining = _workDuration * 60;
      _sessionStartTime = DateTime.now();
    });
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  void _startBreak() {
    final isLongBreak = (_completedSessions + 1) % _sessionsBeforeLongBreak == 0;
    setState(() {
      _state = isLongBreak ? PomodoroState.longBreak : PomodoroState.shortBreak;
      _timeRemaining = (isLongBreak ? _longBreakDuration : _breakDuration) * 60;
    });
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    
    if (_state == PomodoroState.working) {
      _completedSessions++;
      _saveSession();
      _showCompletionDialog();
    } else {
      setState(() {
        _state = PomodoroState.idle;
        _timeRemaining = _workDuration * 60;
      });
    }
  }

  Future<void> _saveSession() async {
    final session = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: widget.linkedTodo?.id,
      todoTitle: widget.linkedTodo?.title,
      startTime: _sessionStartTime ?? DateTime.now(),
      endTime: DateTime.now(),
      durationMinutes: _workDuration,
      completed: true,
    );
    
    await FirestoreService.instance.createPomodoroSession(session);
    
    // Update todo pomodoro count if linked
    if (widget.linkedTodo != null) {
      widget.linkedTodo!.pomodoroSessions++;
      await FirestoreService.instance.updateTodo(widget.linkedTodo!);
    }

    // Check for achievements
    final totalSessions = await FirestoreService.instance.getTotalPomodoroSessions();
    if (mounted) {
      context.read<UserProvider>().addPomodoroAchievement(totalSessions);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.panel : AppColors.lightPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 28)),
            Text(
              'Session Complete!',
              style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great focus! You completed $_completedSessions session${_completedSessions > 1 ? 's' : ''} today.',
              style: TextStyle(color: context.textMutedColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Time for a ${(_completedSessions % _sessionsBeforeLongBreak == 0) ? 'long' : 'short'} break!',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _state = PomodoroState.idle;
                _timeRemaining = _workDuration * 60;
              });
            },
            child: Text('Skip Break', style: TextStyle(color: context.textMutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startBreak();
            },
            child: const Text('Start Break', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    if (_state == PomodoroState.paused) {
      setState(() => _state = PomodoroState.working);
      _startTimer();
    } else if (_state == PomodoroState.working || 
               _state == PomodoroState.shortBreak || 
               _state == PomodoroState.longBreak) {
      _timer?.cancel();
      setState(() => _state = PomodoroState.paused);
    }
    HapticFeedback.lightImpact();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = PomodoroState.idle;
      _timeRemaining = _workDuration * 60;
    });
    HapticFeedback.lightImpact();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress {
    int totalSeconds;
    switch (_state) {
      case PomodoroState.working:
      case PomodoroState.paused:
        totalSeconds = _workDuration * 60;
        break;
      case PomodoroState.shortBreak:
        totalSeconds = _breakDuration * 60;
        break;
      case PomodoroState.longBreak:
        totalSeconds = _longBreakDuration * 60;
        break;
      case PomodoroState.idle:
        return 0;
    }
    return 1 - (_timeRemaining / totalSeconds);
  }

  Color get _stateColor {
    switch (_state) {
      case PomodoroState.working:
        return AppColors.danger;
      case PomodoroState.shortBreak:
      case PomodoroState.longBreak:
        return AppColors.success;
      case PomodoroState.paused:
        return AppColors.warning;
      case PomodoroState.idle:
        return AppColors.accent;
    }
  }

  String get _stateLabel {
    switch (_state) {
      case PomodoroState.working:
        return 'Focus Time';
      case PomodoroState.shortBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break';
      case PomodoroState.paused:
        return 'Paused';
      case PomodoroState.idle:
        return 'Ready to Focus';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch user provider for settings
    context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  _stateColor.withValues(alpha: 0.15),
                  context.backgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.surfaceElevatedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineColor),
                          ),
                          child: Icon(Icons.arrow_back, color: context.textPrimaryColor),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            'Pomodoro Timer',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _stateLabel,
                            style: TextStyle(color: _stateColor, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.outlineColor),
                        ),
                        child: Row(
                          children: [
                            const Text('🍅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              '$_completedSessions',
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Linked task
                if (widget.linkedTodo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.outlineColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: AppColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Working on',
                                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                                ),
                                Text(
                                  widget.linkedTodo!.title,
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '🍅 ${widget.linkedTodo!.pomodoroSessions}',
                            style: TextStyle(color: context.textMutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Timer circle
                ScaleTransition(
                  scale: _state == PomodoroState.working ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: _stateColor.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 12,
                            backgroundColor: context.outlineColor,
                            valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
                          ),
                        ),
                        // Time display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_timeRemaining),
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _state == PomodoroState.idle 
                                  ? 'Tap Start to begin'
                                  : _stateLabel,
                              style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Session indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_sessionsBeforeLongBreak, (index) {
                      final isCompleted = index < (_completedSessions % _sessionsBeforeLongBreak);
                      final isCurrent = index == (_completedSessions % _sessionsBeforeLongBreak) &&
                          _state == PomodoroState.working;
                      return Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted 
                              ? AppColors.success 
                              : isCurrent 
                                  ? _stateColor.withValues(alpha: 0.5)
                                  : context.outlineColor,
                          border: Border.all(
                            color: isCurrent ? _stateColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  '${_completedSessions % _sessionsBeforeLongBreak} of $_sessionsBeforeLongBreak until long break',
                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                ),

                const SizedBox(height: 32),

                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_state != PomodoroState.idle) ...[
                        // Reset button
                        GestureDetector(
                          onTap: _reset,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.surfaceColor,
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: Icon(Icons.refresh, color: context.textMutedColor, size: 28),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                      
                      // Main button
                      GestureDetector(
                        onTap: () {
                          if (_state == PomodoroState.idle) {
                            _startWork();
                          } else {
                            _togglePause();
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_stateColor, _stateColor.withValues(alpha: 0.8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _stateColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _state == PomodoroState.idle 
                                ? Icons.play_arrow
                                : _state == PomodoroState.paused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      if (_state != PomodoroState.idle) ...[
                        const SizedBox(width: 24),
                        // Skip button
                        GestureDetector(
                          onTap: _onTimerComplete,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.surfaceColor,
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: Icon(Icons.skip_next, color: context.textMutedColor, size: 28),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

