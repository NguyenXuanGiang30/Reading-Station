/// FlashcardSessionScreen - Phiên ôn tập flashcard với SM-2
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flip_card/flip_card.dart';

import '../../theme/colors.dart';
import '../../services/flashcard_service.dart';
import '../../models/flashcard.dart';

class FlashcardSessionScreen extends StatefulWidget {
  final String? deckId;
  
  const FlashcardSessionScreen({super.key, this.deckId});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  final FlashcardService _service = FlashcardService();
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _sessionComplete = false;
  bool _isLoading = true;
  String? _error;
  
  // Session stats
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalCards = 0;
  
  // Flashcards from API
  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }
  
  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final cards = await _service.getDueCards(deckId: widget.deckId, limit: 20);
      if (mounted) {
        setState(() {
          _flashcards = cards;
          _totalCards = cards.length;
          _isLoading = false;
          if (cards.isEmpty) {
            _sessionComplete = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _nextCard() {
    if (_cardKey.currentState?.isFront == false) {
      _cardKey.currentState?.toggleCard();
    }
    
    setState(() {
      _showAnswer = false;
      if (_currentIndex < _flashcards.length - 1) {
        _currentIndex++;
      } else {
        _sessionComplete = true;
      }
    });
  }

  Future<void> _rateCard(int quality) async {
    // SM-2 quality: 0 = Again, 1 = Hard, 2 = Good, 3 = Easy
    if (quality >= 2) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }
    
    // Submit review to API
    try {
      final card = _flashcards[_currentIndex];
      await _service.submitReview(card.id, quality);
    } catch (e) {
      // Ignore review errors silently
    }
    
    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/review'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryStart),
              SizedBox(height: 16),
              Text('Đang tải flashcard...'),
            ],
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFlashcards,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_sessionComplete) {
      return _buildCompletionScreen(context, isDark);
    }
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${_flashcards.length}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Session settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _flashcards.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryStart),
            minHeight: 4,
          ),
          
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBadge(Icons.check, _correctCount, AppColors.success),
                const SizedBox(width: 24),
                _buildStatBadge(Icons.close, _incorrectCount, AppColors.error),
              ],
            ),
          ),
          
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildFlashcard(isDark),
            ),
          ),
          
          // Rating buttons
          if (_showAnswer)
            _buildRatingButtons(isDark)
          else
            _buildShowAnswerButton(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard(bool isDark) {
    final card = _flashcards[_currentIndex];
    
    return FlipCard(
      key: _cardKey,
      direction: FlipDirection.HORIZONTAL,
      flipOnTouch: true,
      onFlip: () {
        setState(() {
          _showAnswer = true;
        });
      },
      front: _buildCardSide(
        content: card.question,
        label: 'Câu hỏi',
        isDark: isDark,
        isFront: true,
      ),
      back: _buildCardSide(
        content: card.answer,
        label: 'Câu trả lời',
        isDark: isDark,
        isFront: false,
        bookName: card.bookTitle,
      ),
    );
  }

  Widget _buildCardSide({
    required String content,
    required String label,
    required bool isDark,
    required bool isFront,
    String? bookName,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isFront
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isFront ? AppColors.primaryStart : const Color(0xFF11998e))
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Center(
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Book name
            if (bookName != null)
              Text(
                '📚 $bookName',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            
            // Tap hint
            if (isFront) ...[
              const SizedBox(height: 12),
              Text(
                'Chạm để lật thẻ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            _cardKey.currentState?.toggleCard();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Hiện câu trả lời',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Bạn nhớ được bao nhiêu?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRatingButton(
                  label: 'Quên',
                  color: AppColors.error,
                  quality: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Khó',
                  color: AppColors.warning,
                  quality: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Tốt',
                  color: AppColors.info,
                  quality: 2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Dễ',
                  color: AppColors.success,
                  quality: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required Color color,
    required int quality,
  }) {
    return ElevatedButton(
      onPressed: () => _rateCard(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, bool isDark) {
    final accuracy = _totalCards > 0 
        ? (_correctCount / _totalCards * 100).toInt() 
        : 0;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Hoàn thành! 🎉',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Bạn đã ôn xong $_totalCards thẻ',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompletionStat(
                          value: '$_correctCount',
                          label: 'Đúng',
                          color: AppColors.success,
                        ),
                        _buildCompletionStat(
                          value: '$_incorrectCount',
                          label: 'Sai',
                          color: AppColors.error,
                        ),
                        _buildCompletionStat(
                          value: '$accuracy%',
                          label: 'Chính xác',
                          color: AppColors.primaryStart,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Accuracy bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          accuracy >= 70 ? AppColors.success : AppColors.warning,
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _correctCount = 0;
                          _incorrectCount = 0;
                          _sessionComplete = false;
                          _showAnswer = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ôn lại',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryStart,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Hoàn tất',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStat({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc phiên ôn tập?'),
        content: const Text('Tiến độ hiện tại sẽ được lưu lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/review');
            },
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
  }
}
