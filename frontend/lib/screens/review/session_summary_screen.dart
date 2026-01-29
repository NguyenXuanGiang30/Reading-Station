/// SessionSummaryScreen - Tổng kết sau phiên ôn tập flashcard
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import '../../theme/colors.dart';

class SessionSummaryScreen extends StatefulWidget {
  final int totalCards;
  final int correctCards;
  final int incorrectCards;
  final int timeSpentSeconds;
  final String? deckName;
  
  const SessionSummaryScreen({
    super.key,
    required this.totalCards,
    required this.correctCards,
    required this.incorrectCards,
    this.timeSpentSeconds = 0,
    this.deckName,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  late ConfettiController _confettiController;
  
  double get accuracy => widget.totalCards > 0 
      ? (widget.correctCards / widget.totalCards * 100) 
      : 0;
  
  String get grade {
    if (accuracy >= 90) return 'Xuất sắc! 🏆';
    if (accuracy >= 70) return 'Tốt lắm! 👏';
    if (accuracy >= 50) return 'Khá tốt! 💪';
    return 'Cố gắng hơn! 📚';
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Play confetti if performance is good
    if (accuracy >= 70) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds giây';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins phút $secs giây';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => context.go('/review'),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                
                const Spacer(),
                
                // Grade
                Text(
                  grade,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Deck name
                if (widget.deckName != null)
                  Text(
                    widget.deckName!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Accuracy circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${accuracy.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Độ chính xác',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        value: widget.totalCards.toString(),
                        label: 'Tổng thẻ',
                        icon: Icons.style,
                      ),
                      _buildStatItem(
                        value: widget.correctCards.toString(),
                        label: 'Đúng',
                        icon: Icons.check_circle,
                        color: AppColors.success,
                      ),
                      _buildStatItem(
                        value: widget.incorrectCards.toString(),
                        label: 'Sai',
                        icon: Icons.cancel,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Time spent
                if (widget.timeSpentSeconds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(widget.timeSpentSeconds),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Continue learning
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Start new session
                            context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryStart,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Học tiếp',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Done
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/review'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Hoàn thành',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
