import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:eindopdracht/providers/groups_provider.dart';
import 'package:eindopdracht/providers/transaction_provider.dart';
import 'package:eindopdracht/widgets/common/form_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../signup/signup_screen.dart';
import 'password_reset_screen.dart';
import '../../core/services/auth_service.dart'; // Import auth service

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Load saved credentials and auto-login if possible
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try auto-login first
      final autoLoginSuccessful = await _authService.tryAutoLogin();

      if (autoLoginSuccessful) {
        // If auto-login is successful, navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
          return;
        }
      }

      // If auto-login fails, load saved credentials to the form
      final credentials = await _authService.getSavedLoginCredentials();

      if (mounted) {
        setState(() {
          _emailController.text = credentials['email'] ?? '';
          _passwordController.text = credentials['password'] ?? '';
          _rememberMe = credentials['rememberMe'] ?? false;
        });
      }
    } catch (e) {
      // Handle errors silently - user will need to log in manually
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    // Validate inputs first
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("Login attempt with email: ${_emailController.text.trim()}");

      // Sign in with Firebase using email and password
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print("Login successful with user ID: ${result.user?.uid}");

      // Save credentials if remember me is checked
      await _authService.saveLoginCredentials(
        _emailController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );

      // Check if we're still logged in after the type error
      if (_authService.isLoggedIn) {
        // Continue with logged in user flow even if there was a type error
        print("User is logged in according to AuthService.isLoggedIn");

        // Refresh groups data after successful login
        if (mounted) {
          try {
            await Provider.of<GroupsProvider>(
              context,
              listen: false,
            ).handleAuthStateChanged();
          } catch (e) {
            print("Error refreshing groups: $e");
            // Continue even if groups refresh fails
          }
        }

        // Also refresh transaction data
        if (mounted) {
          try {
            await Provider.of<TransactionProvider>(
              context,
              listen: false,
            ).handleAuthStateChanged();
          } catch (e) {
            print("Error refreshing transactions: $e");
            // Continue even if transactions refresh fails
          }
        }

        // If we get here, login was successful
        // Navigate to the home screen
        if (mounted) {
          print("Navigating to home screen after successful login");
          Navigator.of(context).pushReplacementNamed('/');
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception during login: ${e.code} - ${e.message}");

      // Special handling for the type error we identified
      if (e.code == 'type-error') {
        // The user is actually authenticated despite the error
        if (_authService.isLoggedIn) {
          print(
              "User is logged in despite type error, proceeding with login flow");

          // Save credentials if remember me is checked
          await _authService.saveLoginCredentials(
            _emailController.text.trim(),
            _passwordController.text,
            _rememberMe,
          );

          if (mounted) {
            // Refresh data and navigate to home
            try {
              await Provider.of<GroupsProvider>(context, listen: false)
                  .handleAuthStateChanged();
              await Provider.of<TransactionProvider>(context, listen: false)
                  .handleAuthStateChanged();
              Navigator.of(context).pushReplacementNamed('/');
              return;
            } catch (refreshError) {
              print("Error refreshing data after type error: $refreshError");
              // If we can't refresh data, at least navigate to home
              Navigator.of(context).pushReplacementNamed('/');
              return;
            }
          }
        }
      }

      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Invalid email format.';
        } else if (e.code == 'user-disabled') {
          _errorMessage = 'This account has been disabled.';
        } else if (e.code == 'network-request-failed') {
          _errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.code == 'type-error') {
          _errorMessage = 'Authentication error. Please try again.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      print("General exception during login: $e");

      // Check if the user is actually logged in despite the error
      if (_authService.isLoggedIn) {
        print("Login successful despite error, proceeding with login flow");

        // Save credentials if remember me is checked
        await _authService.saveLoginCredentials(
          _emailController.text.trim(),
          _passwordController.text,
          _rememberMe,
        );

        if (mounted) {
          try {
            await Provider.of<GroupsProvider>(context, listen: false)
                .handleAuthStateChanged();
            await Provider.of<TransactionProvider>(context, listen: false)
                .handleAuthStateChanged();
            Navigator.of(context).pushReplacementNamed('/');
            return;
          } catch (refreshError) {
            print("Error refreshing data after general error: $refreshError");
            // If we can't refresh data, at least navigate to home
            Navigator.of(context).pushReplacementNamed('/');
            return;
          }
        }
      } else {
        setState(() {
          if (e is TypeError) {
            _errorMessage = 'A technical error occurred. Please try again.';
          } else {
            _errorMessage = 'An unexpected error occurred. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signup() {
    // Navigate to the signup screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Receipt Tracker',
                        style: AppStyles.heading.copyWith(
                          fontSize: 28.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48.0),

                // Email field
                FormFieldWidget(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),

                // Password field
                FormFieldWidget(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: AppStyles.body.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Remember me checkbox
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        checkColor: AppColors.primary,
                        fillColor: MaterialStateProperty.resolveWith(
                          (states) => AppColors.getBackgroundColor(context),
                        ),
                        side: MaterialStateBorderSide.resolveWith(
                          (states) =>
                              BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      Text('Remember me',
                          style: AppStyles.body.copyWith(
                              color: AppColors.getTextColor(context))),
                      const Spacer(),
                      TextButton(
                        child: Text(
                          'Forgot Password?',
                          style: AppStyles.body.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PasswordResetScreen(
                                email: _emailController.text.trim(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Login button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: AppStyles.subheading.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                const SizedBox(height: 24.0),

                // Sign up option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppStyles.caption
                            .copyWith(color: AppColors.getTextColor(context))),
                    TextButton(
                      onPressed: _signup,
                      child: Text(
                        'Sign Up',
                        style: AppStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
