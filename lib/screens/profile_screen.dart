import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finlife/screens/auth_screen.dart';
import 'package:finlife/screens/achievements_screen.dart';
import 'package:finlife/screens/onboarding_screen.dart';
import '../providers/user_provider.dart';
import '../providers/database_provider.dart';
import '../providers/transaction_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _monthlyIncomeController;
  final _apiKeyController = TextEditingController();
  bool _apiKeySaved = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProvider);
    _nameController = TextEditingController(text: userState.user?.name ?? '');
    _emailController = TextEditingController(text: userState.user?.email ?? '');
    _monthlyIncomeController = TextEditingController(
      text: userState.user?.monthlyIncome != null
          ? userState.user!.monthlyIncome.toString()
          : '',
    );
    _loadApiKey();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _monthlyIncomeController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('groq_api_key') ?? '';
    setState(() {
      _apiKeyController.text = key;
      _apiKeySaved = key.isNotEmpty;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите API ключ'), backgroundColor: Colors.red),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', key);
    setState(() => _apiKeySaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API ключ сохранён ✅'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spacingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(userState),
                      const SizedBox(height: AppStyles.spacingLarge),
                      _buildProfileForm(),
                      const SizedBox(height: AppStyles.spacingLarge),
                      _buildSaveButton(),
                      const SizedBox(height: AppStyles.spacingLarge),
                      _buildApiKeySection(),
                      const SizedBox(height: AppStyles.spacingLarge),
                      _buildGamificationSection(),
                      const SizedBox(height: AppStyles.spacingLarge),
                      _buildLogoutButton(),
                      const SizedBox(height: AppStyles.spacingMedium),
                      _buildResetButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildApiKeySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('ИИ-советник (Groq)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_apiKeySaved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✅ Активен',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Бесплатный ИИ для персональных советов по расходам.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Получить ключ бесплатно: console.groq.com',
            style: TextStyle(
              color: Color(0xFF7B61FF),
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              labelText: 'Groq API ключ',
              hintText: 'gsk_...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.key, color: Color(0xFF7B61FF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveApiKey,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить ключ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserState state) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 30, color: AppColors.surface),
        ),
        const SizedBox(width: AppStyles.spacingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.user?.name ?? 'Пользователь', style: AppStyles.headline3),
            Text(state.user?.email ?? '', style: AppStyles.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Личная информация', style: AppStyles.headline4),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _nameController,
          decoration: AppStyles.inputDecoration('Имя'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите имя';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _emailController,
          decoration: AppStyles.inputDecoration('Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите email';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Некорректный email';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _monthlyIncomeController,
          decoration: AppStyles.inputDecoration('Ежемесячный доход (₽)'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите доход';
            if (double.tryParse(value) == null) return 'Введите число';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          ),
        ),
        child: const Text('Сохранить', style: AppStyles.button),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранен')),
      );
    }
  }

  Widget _buildGamificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Геймификация', style: AppStyles.headline4),
        const SizedBox(height: AppStyles.spacingMedium),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          ),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.primary),
            title: const Text('Достижения'),
            subtitle: const Text('Посмотреть все достижения'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AchievementsScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          ),
        ),
        child: const Text('Выйти из аккаунта',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
    }
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _resetAll,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          ),
        ),
        child: const Text('Сбросить всё',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вы уверены?'),
        content: const Text('Все данные будут удалены'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userState = ref.read(userProvider);
        final userId = userState.user?.id ?? 'user_1';
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        final database = ref.read(databaseProvider);
        await database.deleteTransactionsByUser(userId);
        await database.deleteFinancialGoalsByUser(userId);
        await database.deleteBudgetsByUser(userId);
        await database.deleteGamificationByUser(userId);
        await database.deleteUser(userId);
        ref.read(transactionProvider.notifier).state = TransactionState();
        if (mounted) {
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()), (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при сбросе данных')),
          );
        }
      }
    }
  }
}