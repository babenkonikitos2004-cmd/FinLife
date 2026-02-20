import 'package:flutter/material.dart';
import 'package:finlife/screens/onboarding_screen.dart';
import 'package:finlife/screens/home_screen.dart';
import 'package:finlife/screens/survey_screen.dart';
import 'package:finlife/screens/history_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finlife/providers/category_provider.dart';

void main() {
  initializeDateFormatting('ru', null);
  runApp(const ProviderScope(child: FinLifeApp()));
}

class FinLifeApp extends StatelessWidget {
  const FinLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinLife - Умные Финансы',
      theme: ThemeData(
        primaryColor: const Color(0xFF7B61FF),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF7B61FF),
          secondary: const Color(0xFF7B61FF),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/survey': (context) => const SurveyScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading time
    Future.delayed(const Duration(seconds: 2), () {
      // Check if user has completed onboarding
      final bool hasCompletedOnboarding = false; // Replace with actual check
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => hasCompletedOnboarding
                ? const HomeScreen()
                : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'FinLife',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Умные Финансы',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}