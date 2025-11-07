import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import 'input_field.dart';

class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key});

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();

      if (mounted && userCredential != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed in with Google')));

        // Small delay to ensure authentication state is updated
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // Navigate to splash screen after successful sign-in
          context.go('/splash');
        }
      } else {
        // Sign-in failed or canceled
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed in successfully')));
        // Explicitly navigate to splash screen after successful sign-in
        context.go('/splash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAccountWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.createAccountWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        // Explicitly navigate to splash screen after successful account creation
        context.go('/splash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Account creation failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGoogleSignInButton(ThemeData theme) {
    // Determine if we're in dark or light mode
    final isDark = theme.brightness == Brightness.dark;
    final themeFolder = isDark ? 'dark' : 'light';

    // Get device pixel ratio to choose appropriate resolution
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    String resolution;
    if (devicePixelRatio >= 4.0) {
      resolution = '4x';
    } else if (devicePixelRatio >= 3.0) {
      resolution = '3x';
    } else if (devicePixelRatio >= 2.0) {
      resolution = '2x';
    } else {
      resolution = '1x';
    }

    // Build asset path with appropriate resolution - using square version (sq_ctn)
    final assetPath =
        'assets/google_button/png$resolution/$themeFolder/android_${themeFolder}_sq_ctn$resolution.png';

    // Fallback resolutions in case primary fails
    final fallbackPaths = [
      if (resolution != '2x')
        'assets/google_button/png2x/$themeFolder/android_${themeFolder}_sq_ctn2x.png',
      if (resolution != '1x')
        'assets/google_button/png1x/$themeFolder/android_${themeFolder}_sq_ctn1x.png',
    ];

    return SizedBox(
      width: double.infinity,
      height: 48, // Standard button height
      child: GestureDetector(
        onTap: _isLoading ? null : _signInWithGoogle,
        child: Opacity(
          opacity: _isLoading ? 0.6 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              8,
            ), // Match Google button rounded corners
            child: _buildGoogleButtonImage(assetPath, fallbackPaths, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButtonImage(
    String primaryPath,
    List<String> fallbackPaths,
    ThemeData theme,
  ) {
    // Use appropriate cache dimensions - Google buttons are typically 320dp wide
    // Scale based on device pixel ratio for optimal quality
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate cache width: screen width * pixel ratio, but cap for performance
    final cacheWidth = (screenWidth * devicePixelRatio).round().clamp(320, 960);

    return Image.asset(
      primaryPath,
      width: double.infinity,
      height: 48,
      fit: BoxFit.scaleDown, // Scale down if needed, maintain aspect ratio
      alignment: Alignment.center,
      cacheWidth: cacheWidth,
      cacheHeight: (48 * devicePixelRatio).round().clamp(48, 144),
      errorBuilder: (context, error, stackTrace) {
        // Try fallback paths
        if (fallbackPaths.isNotEmpty) {
          return _buildGoogleButtonImage(
            fallbackPaths.first,
            fallbackPaths.sublist(1),
            theme,
          );
        }

        // Final fallback to a simple button
        return OutlinedButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(color: theme.colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PomoDojo',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Image.asset(
                        'assets/images/apprentice_1.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 80,
                            color: theme.colorScheme.primary,
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Login Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              AppInputField(
                                controller: _displayNameController,
                                label: 'Display Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (_isSignUp &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter your display name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                            ],
                            //Email field
                            AppInputField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            //Password field
                            AppInputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (_isSignUp && value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ForgotPasswordDialog(),
                                  );
                                },
                                child: Text(
                                  'Forget password?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            //Log in button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_isSignUp) {
                                          _createAccountWithEmailAndPassword();
                                        } else {
                                          _signInWithEmailAndPassword();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                  disabledBackgroundColor:
                                      theme.colorScheme.secondary,
                                  disabledForegroundColor:
                                      theme.colorScheme.onSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.onSecondary,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Sign Up' : 'Log In',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    'Or sign in with',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            // Google sign-in button
                            _buildGoogleSignInButton(theme),
                            const SizedBox(height: 16.0),
                            // Toggle sign up / log in
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already have an account?'
                                      : 'Don\'t have an account?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  child: Text(
                                    _isSignUp ? 'Log In' : 'Sign Up',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ForgotPasswordDialogState createState() => ForgotPasswordDialogState();
}

class ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            AppInputField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendPasswordReset,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Email'),
        ),
      ],
    );
  }
}
