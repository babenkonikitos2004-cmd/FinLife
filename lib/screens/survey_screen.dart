import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/providers/user_provider.dart';
import 'package:finlife/providers/transaction_provider.dart';
import 'package:finlife/models/user.dart' as model;
import 'package:finlife/screens/home_screen.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  String? _selectedGender;
  int _selectedAge = 25;
  String? _selectedFinancialGoal;
  String? _selectedIncomeRange;

  final List<String> _financialGoals = [
    'Накопить на крупную покупку',
    'Контролировать расходы',
    'Достичь финансовой цели',
    'Накопить на жильё',
    'Начать инвестировать',
  ];

  final List<String> _incomeRanges = [
    'До 30 000 ₽',
    '30 000 - 80 000 ₽',
    '80 000 - 150 000 ₽',
    'Более 150 000 ₽',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Save user data and navigate to home
      _saveUserData();
    }
  }

  void _saveUserData() {
    print('DEBUG: _saveUserData called');
    final userState = ref.read(userProvider);
    print('DEBUG: userState loaded, user is null: ${userState.user == null}');
    
    // Create a new user with the survey data
    final newUser = model.User(
      id: userState.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: userState.user?.name ?? 'Пользователь',
      email: userState.user?.email ?? '',
      monthlyIncome: _getMonthlyIncomeFromRange(_selectedIncomeRange),
      createdAt: userState.user?.createdAt ?? DateTime.now(),
      gender: _selectedGender,
      age: _selectedAge,
      financialGoal: _selectedFinancialGoal,
    );
    
    print('DEBUG: Creating/updating user with data: $newUser');
    
    if (userState.user != null) {
      print('DEBUG: Updating existing user data');
      ref.read(userProvider.notifier).updateUser(newUser);
    } else {
      print('DEBUG: Creating new user');
      ref.read(userProvider.notifier).createUser(newUser);
    }
    
    // Load transactions for the new user
    print('DEBUG: Loading transactions for new user');
    ref.read(transactionProvider.notifier).loadTransactions(newUser.id);
    
    print('DEBUG: Navigating to HomeScreen');
    // Navigate to home screen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  double _getMonthlyIncomeFromRange(String? range) {
    if (range == null) return 50000;
    
    switch (range) {
      case 'До 30 000 ₽':
        return 25000;
      case '30 000 - 80 000 ₽':
        return 55000;
      case '80 000 - 150 000 ₽':
        return 115000;
      case 'Более 150 000 ₽':
        return 200000;
      default:
        return 50000;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildGenderSelectionPage(),
                  _buildAgeSelectionPage(),
                  _buildFinancialGoalPage(),
                  _buildIncomeRangePage(),
                ],
              ),
            ),
            
            // Next button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _currentPage == 3 ? 'Завершить' : 'Далее',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: _currentPage >= index 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGenderSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ваш пол',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Выберите ваш пол',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderCard('Мужчина', '👨', 'male'),
              _buildGenderCard('Женщина', '👩', 'female'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String title, String emoji, String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ваш возраст',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Укажите ваш возраст',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            '$_selectedAge лет',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 30),
          Slider(
            value: _selectedAge.toDouble(),
            min: 16,
            max: 80,
            divisions: 64,
            label: '$_selectedAge лет',
            onChanged: (value) {
              setState(() {
                _selectedAge = value.toInt();
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            '16 - 80 лет',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Финансовая цель',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Выберите вашу основную финансовую цель',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.separated(
              itemCount: _financialGoals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goal = _financialGoals[index];
                final isSelected = _selectedFinancialGoal == goal;
                return _buildGoalCard(goal, isSelected, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String goal, bool isSelected, int index) {
    final emojis = ['💰', '📊', '🎯', '🏠', '📈'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFinancialGoal = goal;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              emojis[index],
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                goal,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeRangePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Уровень дохода',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Выберите ваш среднемесячный доход',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.separated(
              itemCount: _incomeRanges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final range = _incomeRanges[index];
                final isSelected = _selectedIncomeRange == range;
                return _buildIncomeRangeCard(range, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRangeCard(String range, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIncomeRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              range,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}