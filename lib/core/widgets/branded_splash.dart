import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'aiva_wordmark.dart';

/// Branded loading screen shown while the app figures out auth state. The logo
/// breathes (subtle scale + opacity pulse) instead of a bare spinner. Pulse is
/// skipped under reduce-motion.
class BrandedSplash extends StatefulWidget {
  const BrandedSplash({super.key});

  @override
  State<BrandedSplash> createState() => _BrandedSplashState();
}

class _BrandedSplashState extends State<BrandedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final logo = Image.asset('assets/images/aiva_logo.png', width: 96, height: 96);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reduceMotion)
              logo
            else
              ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.06).animate(
                  CurvedAnimation(parent: _controller, curve: AppMotion.standard),
                ),
                child: FadeTransition(
                  opacity: Tween(begin: 0.7, end: 1.0).animate(_controller),
                  child: logo,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            const AivaWordmark(fontSize: 30),
          ],
        ),
      ),
    );
  }
}
