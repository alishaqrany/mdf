import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Animated splash screen with Lottie animation (3 seconds).
///
/// After the animation completes it checks:
///  1. If onboarding has been shown → route to onboarding
///  2. Else check auth state → route to student/admin/login
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Lottie controller — 3 seconds total
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Fade-in for the whole page
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Text slide-up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Start fade-in immediately
    _fadeController.forward();

    // Start lottie after brief delay
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _lottieController.forward();

    // Show text after lottie is midway
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textController.forward();

    // Wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.onboardingKey) ?? false;

    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
    } else {
      // Auth redirect will happen via GoRouter's redirect logic
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.go(authState.user.isAdmin ? '/admin' : '/student');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF4A42E8), Color(0xFF3D35D1)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ─── Lottie Animation ───
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/animations/splash_logo.json',
                    controller: _lottieController,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.school_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ─── App Name ───
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _textController,
                    child: Column(
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Modern Digital Future',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white70,
                                letterSpacing: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ─── Loading Indicator ───
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'v${AppConstants.appVersion}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white38),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
