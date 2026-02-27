import 'package:flutter/material.dart';
import 'package:finlife/screens/onboarding_screen.dart';
import 'package:finlife/screens/home_screen.dart';
import 'package:finlife/screens/survey_screen.dart';
import 'package:finlife/screens/history_screen.dart';
import 'package:finlife/screens/auth_screen.dart';
import 'package:finlife/screens/achievements_screen.dart';
import 'package:finlife/screens/statistics_screen.dart';
import 'package:finlife/screens/goals_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finlife/providers/category_provider.dart';
import 'package:finlife/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finlife/services/recurring_transaction_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/survey': (context) => const SurveyScreen(),
        '/history': (context) => const HistoryScreen(),
        '/achievements': (context) => const AchievementsScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/goals': (context) => const GoalsScreen(),
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userName = prefs.getString('userName');
    final isOnboardingComplete = await _storageService.isOnboardingComplete();
    
    if (mounted) {
      if (isLoggedIn && userName != null) {
        // Check for recurring transactions
        final recurringService = RecurringTransactionService(ref);
        await recurringService.checkAndAddRecurringTransactions('user_$userName');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (isOnboardingComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
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
