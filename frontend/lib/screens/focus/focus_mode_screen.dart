/// FocusModeScreen - Chế độ đọc tập trung Pomodoro
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class FocusModeScreen extends StatefulWidget {
  final String? bookId;
  final String? bookTitle;
  
  const FocusModeScreen({super.key, this.bookId, this.bookTitle});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  // Timer state
  int _selectedDuration = 25; // minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;
  
  // Preset durations
  final List<int> _durations = [15, 25, 45, 60];
  
  // Ambient sounds
  final List<Map<String, dynamic>> _sounds = [
    {'name': 'Không', 'icon': Icons.volume_off},
    {'name': 'Mưa', 'icon': Icons.water_drop},
    {'name': 'Quán cà phê', 'icon': Icons.coffee},
    {'name': 'Rừng', 'icon': Icons.forest},
    {'name': 'Đại dương', 'icon': Icons.waves},
  ];
  int _selectedSound = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _selectedDuration * 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isCompleted = true;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isCompleted = true;
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _remainingSeconds = _selectedDuration * 60;
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  double get _progress {
    final total = _selectedDuration * 60;
    return (total - _remainingSeconds) / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: _isCompleted ? _buildCompletedView() : _buildTimerView(),
      ),
    );
  }

  Widget _buildTimerView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (_isRunning) {
                    _showExitDialog();
                  } else {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              Text(
                'Chế độ tập trung',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // Book info
        if (widget.bookTitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.bookTitle!,
                      style: GoogleFonts.inter(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        const Spacer(),
        
        // Timer display
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
            ),
            Column(
              children: [
                Text(
                  _formatTime(_remainingSeconds),
                  style: GoogleFonts.inter(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                if (!_isRunning && _remainingSeconds == _selectedDuration * 60)
                  Text(
                    'phút',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        // Duration presets (only show when not running)
        if (!_isRunning && _remainingSeconds == _selectedDuration * 60)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _durations.map((d) => _buildDurationChip(d)).toList(),
          ),
        
        const Spacer(),
        
        // Sound selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Âm thanh nền',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sounds.asMap().entries.map((e) {
                    return _buildSoundChip(e.key, e.value);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Control buttons
        Padding(
          padding: const EdgeInsets.all(40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRunning || _remainingSeconds != _selectedDuration * 60)
                IconButton(
                  onPressed: _resetTimer,
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 24),
                  ),
                ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _isRunning ? _pauseTimer : (_remainingSeconds == _selectedDuration * 60 ? _startTimer : _resumeTimer),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              if (_isRunning || _remainingSeconds != _selectedDuration * 60)
                const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(int duration) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
          _remainingSeconds = duration * 60;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryStart : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$duration',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundChip(int index, Map<String, dynamic> sound) {
    final isSelected = _selectedSound == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSound = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryStart.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppColors.primaryStart) : null,
        ),
        child: Row(
          children: [
            Icon(sound['icon'] as IconData, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              sound['name'] as String,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hoàn thành! 🎉',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đã tập trung được $_selectedDuration phút',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _resetTimer,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Tiếp tục',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Kết thúc',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát chế độ tập trung?'),
        content: const Text('Tiến trình hiện tại sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
