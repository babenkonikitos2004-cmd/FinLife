import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserState state) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.person,
            size: 30,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(width: AppStyles.spacingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.user?.name ?? 'Пользователь',
              style: AppStyles.headline3,
            ),
            Text(
              state.user?.email ?? '',
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Личная информация',
          style: AppStyles.headline4,
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _nameController,
          decoration: AppStyles.inputDecoration('Имя'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите имя';
            }
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _emailController,
          decoration: AppStyles.inputDecoration('Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите email';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Пожалуйста, введите корректный email';
            }
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        TextFormField(
          controller: _monthlyIncomeController,
          decoration: AppStyles.inputDecoration('Ежемесячный доход (₽)'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите ежемесячный доход';
            }
            if (double.tryParse(value) == null) {
              return 'Пожалуйста, введите корректное число';
            }
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
      // TODO: Save profile data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранен')),
      );
    }
  }
}