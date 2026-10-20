import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import 'login_page.dart' hide emailRegex;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signOutQuietly() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    bool accountCreated = false;

    try {
      // 1. Firebase Authentication-এ account তৈরি
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Account could not be created.');
      }

      accountCreated = true;

      final name = _nameController.text.trim();

      // 2. Firebase Auth profile-এ নাম সংরক্ষণ
      await user.updateDisplayName(name);

      // 3. Firestore-এ user profile তৈরি
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'profileName': name,
        'nickname': '',
        'bio': '',
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Account তৈরি হয়েছে, তাই এবার sign out
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 5. Login Page-এ নিয়ে যাওয়া
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (error) {
      if (accountCreated) await _signOutQuietly();

      if (!mounted) return;

      setState(() {
        _errorMessage = accountCreated
            ? 'Account created, but setup was incomplete. Please log in.'
            : friendlyAuthError(error);
      });
    } on FirebaseException catch (error) {
      if (accountCreated) await _signOutQuietly();

      if (!mounted) return;

      setState(() {
        _errorMessage = accountCreated
            ? 'Account created, but profile data could not be saved. Please log in.'
            : (error.message ?? 'Firebase error. Please try again.');
      });
    } catch (_) {
      if (accountCreated) await _signOutQuietly();

      if (!mounted) return;

      setState(() {
        _errorMessage = accountCreated
            ? 'Account created, but setup did not finish. Please log in.'
            : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                icon: Icons.rocket_launch_rounded,
                title: 'Create your account',
                subtitle: 'Join ConnectHub and start connecting.',
              ),

              const SizedBox(height: 24),

              AuthInput(
                controller: _nameController,
                label: 'Full name',
                hint: 'Enter your name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Your name is required.';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must contain at least 2 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              AuthInput(
                controller: _emailController,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email is required.';
                  if (!emailRegex.hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              AuthInput(
                controller: _passwordController,
                label: 'Password',
                hint: 'At least 6 characters',
                icon: Icons.lock_outline_rounded,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _hidePassword = !_hidePassword);
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),

              PasswordStrength(controller: _passwordController),

              const SizedBox(height: 16),

              AuthInput(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Enter your password again',
                icon: Icons.verified_user_outlined,
                obscureText: _hideConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hideConfirmPassword = !_hideConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _hideConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorMessage(message: _errorMessage!),
              ],

              const SizedBox(height: 22),

              PrimaryButton(
                label: 'Create Account',
                loading: _loading,
                onPressed: _signUp,
              ),

              const SizedBox(height: 20),
              const OrDivider(),
              const SizedBox(height: 18),

              GoogleSignInButton(
                onPressed: () => _showMessage(
                  'Google Sign-In will be connected in the next step.',
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Already registered?',
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
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
}

