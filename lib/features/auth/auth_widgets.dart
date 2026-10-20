import 'package:connecthub/features/auth/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF5B5CE2);
const Color purpleColor = Color(0xFF7955E8);
const Color inkColor = Color(0xFF202344);
const Color mutedColor = Color(0xFF747994);
const Color pageBackgroundColor = Color(0xFFF5F6FC);
final RegExp emailRegex = RegExp(
  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
);
class AuthFrame extends StatelessWidget {
  final Widget child;

  const AuthFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: Stack(
        children: [
          // Soft background blobs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purpleColor.withValues(alpha: 0.09),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Navigator.of(context).canPop()
                                    ? IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(
                                            color: Color(0xFFE9EAF4),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: inkColor,
                                        ),
                                      )
                                    : const SizedBox(height: 40),
                              ),
                              const SizedBox(height: 8),
                              const FadeSlide(child: _BrandHeader()),
                              const SizedBox(height: 26),
                              FadeSlide(delayMs: 120, child: child),
                              const SizedBox(height: 22),
                              const Text(
                                'YOUR SPACE. YOUR PEOPLE.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedColor,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryColor, purpleColor]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 11),
        const Text(
          'ConnectHub',
          style: TextStyle(
            color: inkColor,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9EAF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34365F).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: inkColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: mutedColor, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
      ],
    );
  }
}

class AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const AuthInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: inkColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: inkColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9A9DB2), fontSize: 13),
            prefixIcon: Icon(icon, color: mutedColor, size: 21),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7F1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Small strength meter shown under the sign-up password field.
class PasswordStrength extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrength({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final password = value.text;
        if (password.isEmpty) return const SizedBox.shrink();

        var score = 0;
        if (password.length >= 6) score++;
        if (password.length >= 10) score++;
        if (RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[0-9]').hasMatch(password)) {
          score++;
        }

        const labels = ['Weak', 'Okay', 'Good', 'Strong'];
        final colors = [
          Colors.redAccent,
          Colors.orange,
          primaryColor,
          Colors.green,
        ];

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: index <= score
                              ? colors[score]
                              : const Color(0xFFE5E7F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                labels[score],
                style: TextStyle(
                  color: colors[score],
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: loading
            ? null
            : [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: inkColor,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E4EF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 11),
            Text(
              'Continue with Google',
              style: TextStyle(color: inkColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE6E7F0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE6E7F0))),
      ],
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB3261E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB3261E),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String friendlyAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
      return 'Incorrect email or password.';
    case 'invalid-credential':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Choose a stronger password.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Check your internet connection.';
    case 'operation-not-allowed':
      return 'Email/Password sign-in is not enabled in Firebase.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
