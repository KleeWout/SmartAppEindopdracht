import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app.dart';
import 'providers/transaction_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_options.dart';

/// Global navigator key used for navigation across the app without context
///
/// This allows navigation actions from services and providers that don't have
/// access to a BuildContext (such as from background processes or after delays).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Application entry point
void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // print("Firebase successfully initialized");

    // Set up Firebase App Check to improve security and prevent abuse
    await FirebaseAppCheck.instance.activate(
    );
    // print("Firebase App Check initialized");

    firebaseInitialized = true;
  } catch (e) {
    // print("Critical error initializing Firebase: $e");
    // App will continue with limited functionality, but authentication won't work
  }

  if (!firebaseInitialized) {
    // print(
    //   "WARNING: Firebase failed to initialize. Authentication will not work.",
    // );
  }

  // Initialize app with all required providers
  runApp(
    MultiProvider(
      providers: [
        // === Service Providers ===

        // Core auth service - base level for authentication operations
        Provider<AuthService>(create: (context) => AuthService()),

        // === Feature Providers ===

        // Auth provider depends on auth service for user management
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, previous) =>
              previous ?? AuthProvider(authService),
        ),

        // Theme provider for light/dark mode management
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

        // Transaction provider for managing financial transactions
        ChangeNotifierProvider(create: (context) => TransactionProvider()),

        // Groups provider for managing expense sharing groups
        ChangeNotifierProvider(create: (context) => GroupsProvider()),

        // Receipt provider for managing receipt data and images
        ChangeNotifierProvider(create: (context) => ReceiptProvider()),

        // Category provider for transaction categorization
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Root widget that handles initial authentication state
///
/// Checks for saved credentials to enable automatic login before
/// showing the main application UI.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Check if user can be automatically logged in using stored credentials
      future: Provider.of<AuthService>(context).tryAutoLogin(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Pass authentication result to main app for proper initial routing
        return ReceiptApp(isLoggedIn: snapshot.data == true);
      },
    );
  }
}
