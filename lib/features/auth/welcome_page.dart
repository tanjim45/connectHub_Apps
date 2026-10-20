import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'auth_widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202457), Color(0xFF5148B9), Color(0xFF8061E9)],
          ),
        ),
        child: Stack(
          children: [
            // Soft decorative circles
            Positioned(
              top: -90,
              right: -70,
              child: _GlowCircle(size: 260, alpha: 0.07),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: _GlowCircle(size: 300, alpha: 0.06),
            ),
            Positioned(
              top: 220,
              left: -40,
              child: _GlowCircle(size: 110, alpha: 0.05),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeSlide(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 54,
                                  width: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.hub_rounded,
                                    color: Colors.white,
                                    size: 31,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                const Text(
                                  'ConnectHub',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 44),

                          // Illustration card
                          FadeSlide(
                            delayMs: 120,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 26,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: const [
                                      _PersonBubble(
                                        color: Color(0xFFFFD7BA),
                                        icon: Icons.person_rounded,
                                        size: 65,
                                      ),
                                      SizedBox(width: 13),
                                      _PersonBubble(
                                        color: Color(0xFFC9C5FF),
                                        icon: Icons.person_rounded,
                                        size: 81,
                                      ),
                                      SizedBox(width: 13),
                                      _PersonBubble(
                                        color: Color(0xFFB9E9DB),
                                        icon: Icons.person_rounded,
                                        size: 65,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  const Text(
                                    'Good people. Great connections.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Your own space to connect and share.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          FadeSlide(
                            delayMs: 240,
                            child: Column(
                              children: [
                                const Text(
                                  'Your world,',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 39,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.3,
                                  ),
                                ),
                                const Text(
                                  'more connected.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFDCD7FF),
                                    fontSize: 34,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Meet people, express yourself, and build '
                                  'meaningful connections in one place.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 15,
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 34),

                          FadeSlide(
                            delayMs: 360,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.18),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _openPage(
                                      context,
                                      const SignUpPage(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.arrow_forward_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.83),
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _openPage(
                                        context,
                                        const LoginPage(),
                                      ),
                                      child: const Text(
                                        'Log In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            '© 2026 MD TANJIM MAHATAB BHUIYAN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.57),
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double alpha;

  const _GlowCircle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _PersonBubble extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const _PersonBubble({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF34365F), size: size * 0.52),
    );
  }
}

// Fade + slide-up entrance animation.
class FadeSlide extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const FadeSlide({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final total = 500 + delayMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

