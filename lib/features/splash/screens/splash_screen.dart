import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _floatController;
  late AnimationController _particleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Logo flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: math.pi, end: 0.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );

    // Gentle float animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

    // Start logo flip after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _flipController.forward();
    });

    // Navigate to home after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.capizBlue,
        child: Stack(
          children: [
            // Animated particles
            ...List.generate(50, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final progress =
                      (_particleController.value + index * 0.02) % 1.0;
                  final size = 1.5 + (index % 4) * 1.5;
                  final x =
                      (index % 7) * 0.14 * MediaQuery.of(context).size.width;
                  final y = progress * MediaQuery.of(context).size.height;

                  return Positioned(
                    left: x + math.sin(progress * math.pi * 2) * 30,
                    top: y,
                    child: Opacity(
                      opacity: 0.3 * (1 - progress),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Flipping logo with float
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _flipAnimation,
                        _floatAnimation,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 240,
                              height: 240,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.location_city,
                                  size: 120,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Minimalist loading dots
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: _buildLoadingDots(),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_particleController.value + delay) % 1.0;
            final scale = 0.6 + (math.sin(progress * math.pi * 2) * 0.4);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.capizGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
