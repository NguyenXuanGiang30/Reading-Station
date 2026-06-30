/// SplashScreen - Màn hình chào mừng
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _scale = Tween(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppDurations.playful),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppDurations.emphasized),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFirstTime) {
          context.go('/onboarding');
        } else if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.warmHero),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: _BlurOrb(
                  color: Colors.white.withValues(alpha: 0.42),
                  size: 220,
                ),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: _BlurOrb(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  size: 260,
                ),
              ),
              SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 62,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            Text(
                              S.of(context).t('splash_app_name'),
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              S.of(context).t('splash_tagline'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            Column(
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.primary,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  S.of(context).t('splash_loading'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
