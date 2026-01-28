import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'services/notification_helper.dart';
import 'services/preferences_service.dart';
import 'services/recurring_payment_service.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();
  await notificationHelper.requestPermissions();
  
  // Initialize recurring payment background task
  final recurringService = RecurringPaymentService();
  await recurringService.initBackgroundTask();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'My Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        cardColor: const Color(0xFF171A21),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SecurityService _securityService = SecurityService();
  final PreferencesService _prefs = PreferencesService();
  bool _isAuthenticating = true;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    // Check if biometric lock is enabled
    final bool isBiometricEnabled = await _prefs.isBiometricEnabled();
    
    bool authenticated = true;
    
    // Only authenticate if biometric lock is enabled
    if (isBiometricEnabled) {
      authenticated = await _securityService.authenticateUser();
    }

    if (mounted) {
      if (authenticated) {
        // Navigate to HomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _isAuthenticating = false;
          _authFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Authenticating...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Authentication failed screen
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to verify your identity.\nYour financial data is protected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
