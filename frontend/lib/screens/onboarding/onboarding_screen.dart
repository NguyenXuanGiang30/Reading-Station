/// OnboardingScreen - Giới thiệu 3 tính năng chính
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/primary_button.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _getPages(BuildContext context) {
    return [
      OnboardingData(
        icon: Icons.local_library_rounded,
        title: S.of(context).t('onboarding_t1'),
        description: S.of(context).t('onboarding_d1'),
        gradient: AppColors.primaryGradient,
      ),
      OnboardingData(
        icon: Icons.camera_alt_rounded,
        title: S.of(context).t('onboarding_t2'),
        description: S.of(context).t('onboarding_d2'),
        gradient: AppGradients.sunriseAccent,
      ),
      OnboardingData(
        icon: Icons.auto_awesome_rounded,
        title: S.of(context).t('onboarding_t3'),
        description: S.of(context).t('onboarding_d3'),
        gradient: AppColors.successGradient,
      ),
    ];
  }

  void _completeOnboarding() {
    context.read<AuthBloc>().completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.editorialSurface,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(S.of(context).t('onboarding_skip')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _getPages(context).length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final data = _getPages(context)[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              gradient: data.gradient,
                              borderRadius: BorderRadius.circular(44),
                              boxShadow: [
                                BoxShadow(
                                  color: data.gradient.colors.last.withValues(
                                    alpha: 0.24,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Icon(
                              data.icon,
                              size: 108,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          Text(
                            data.title,
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            data.description,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _getPages(context).length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PrimaryButton(
                  label: _currentPage == _getPages(context).length - 1
                      ? S.of(context).t('onboarding_start')
                      : S.of(context).t('onboarding_next'),
                  onPressed: () {
                    if (_currentPage == _getPages(context).length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
