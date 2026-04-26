import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.95,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: RepaintBoundary(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 208,
                        height: 208,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x183A6CCB),
                            width: 1.2,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x103A6CCB),
                              blurRadius: 42,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 172,
                        height: 172,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x123A6CCB),
                        ),
                      ),
                      Container(
                        width: 132,
                        height: 132,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x120C1E33),
                              blurRadius: 24,
                              offset: Offset(0, 14),
                            ),
                            BoxShadow(
                              color: Color(0x143A6CCB),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const Positioned(bottom: 26, child: _ShadowBase()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShadowBase extends StatelessWidget {
  const _ShadowBase();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 108,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: <Color>[Color(0x120C1E33), Color(0x000C1E33)],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x120C1E33),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
