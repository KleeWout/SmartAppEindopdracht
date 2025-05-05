import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../widgets/common/form_field_widget.dart';
import '../../providers/groups_provider.dart';
import '../../providers/transaction_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordMatchError;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // Add listeners for real-time password matching validation
    _confirmPasswordController.addListener(_checkPasswordsMatch);
    _passwordController.addListener(_checkPasswordsMatch);
  }

  // Check if passwords match in real-time
  void _checkPasswordsMatch() {
    if (_confirmPasswordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _passwordMatchError = 'Passwords do not match';
        });
      } else {
        setState(() {
          _passwordMatchError = null;
        });
      }
    } else {
      setState(() {
        _passwordMatchError = null;
      });
    }
  }

  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter an email address.');
      return false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a password.');
      return false;
    }

    // Enhanced password validation
    final String password = _passwordController.text;
    if (password.length < 8) {
      setState(
          () => _errorMessage = 'Password must be at least 8 characters long.');
      return false;
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must contain at least one uppercase letter.');
      return false;
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must contain at least one lowercase letter.');
      return false;
    }

    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(
          () => _errorMessage = 'Password must contain at least one number.');
      return false;
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must contain at least one special character.');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return false;
    }

    return true;
  }

  Future<void> _signup() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save additional user information to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'userId': userCredential.user!.uid,
      });

      // Create an empty groups subcollection to ensure proper structure
      // This prevents permission errors when trying to access groups later
      final userDocRef =
          _firestore.collection('users').doc(userCredential.user!.uid);

      // Create a default group for the user
      final defaultGroup = {
        'id': userCredential.user!.uid, // Fix: Remove the curly braces
        'name': 'Personal',
        'description': 'Your default personal expense group',
        'creatorId': userCredential.user!.uid,
        'createdAt': Timestamp.now(),
        'isFavorite': true,
        'color': 0xFF4CAF50, // Green color
      };

      // Add default group to main groups collection
      await _firestore
          .collection('groups')
          .doc(defaultGroup['id'].toString())
          .set(defaultGroup);

      // Add reference to the group in user's groups subcollection
      await userDocRef
          .collection('groups')
          .doc(defaultGroup['id'].toString())
          .set(defaultGroup);

      if (mounted) {
        // Initialize providers for the new user
        final context = this.context;
        try {
          // Initialize providers to ensure Firestore access
          await Provider.of<GroupsProvider>(context, listen: false)
              .handleAuthStateChanged();
          await Provider.of<TransactionProvider>(context, listen: false)
              .handleAuthStateChanged();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate directly to home screen
          Navigator.of(context).pushReplacementNamed('/');
        } catch (e) {
          print('Error initializing data after signup: $e');
          // Fall back to login screen if there's an error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'An account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Invalid email format.';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getColor(context, AppColors.text, Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: AppStyles.heading.copyWith(
                    fontSize: 28.0,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Sign up to start tracking your receipts',
                  style: AppStyles.body.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 32.0),

                // Name field
                FormFieldWidget(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16.0),

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
                  hint: 'Create a password',
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
                const SizedBox(height: 16.0),

                // Confirm Password field
                FormFieldWidget(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  errorText: _passwordMatchError,
                ),
                const SizedBox(height: 8.0),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: AppStyles.body.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24.0),

                // Sign up button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _signup,
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
                          'Sign Up',
                          style: AppStyles.subheading.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                const SizedBox(height: 24.0),

                // Terms and conditions
                Text(
                  '',
                  style: AppStyles.smallText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
