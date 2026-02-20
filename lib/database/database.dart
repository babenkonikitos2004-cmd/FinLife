import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Categories, Transactions, Budgets, FinancialGoals, Gamification])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories
        await into(categories).insert(CategoriesCompanion(
          id: const Value('salary'),
          name: const Value('Зарплата'),
          icon: const Value('work'),
          isIncome: const Value(true),
        ));
        await into(categories).insert(CategoriesCompanion(
          id: const Value('freelance'),
          name: const Value('Фриланс'),
          icon: const Value('computer'),
          isIncome: const Value(true),
        ));
        await into(categories).insert(CategoriesCompanion(
          id: const Value('food'),
          name: const Value('Еда'),
          icon: const Value('restaurant'),
          isIncome: const Value(false),
        ));
        await into(categories).insert(CategoriesCompanion(
          id: const Value('transport'),
          name: const Value('Транспорт'),
          icon: const Value('directions_car'),
          isIncome: const Value(false),
        ));
        await into(categories).insert(CategoriesCompanion(
          id: const Value('health'),
          name: const Value('Здоровье'),
          icon: const Value('local_hospital'),
          isIncome: const Value(false),
        ));
        await into(categories).insert(CategoriesCompanion(
          id: const Value('entertainment'),
          name: const Value('Развлечения'),
          icon: const Value('movie'),
          isIncome: const Value(false),
        ));
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(transactions, transactions.isRecurring);
        }
        if (from < 3) {
          // Fix categories table primary key issue by dropping and recreating
          await customStatement('DROP TABLE IF EXISTS categories');
          await m.createTable(categories);
        }
        if (from < 4) {
          // Remove unique constraint on email column in users table
          await customStatement('CREATE TABLE users_new (id TEXT NOT NULL UNIQUE, name TEXT, email TEXT, monthly_income REAL, created_at TEXT, gender TEXT, age INTEGER, financial_goal TEXT, PRIMARY KEY (id))');
          await customStatement('INSERT INTO users_new SELECT * FROM users');
          await customStatement('DROP TABLE users');
          await customStatement('ALTER TABLE users_new RENAME TO users');
        }
        if (from < 5) {
          // Insert default categories if they don't exist
          final existingCategories = await select(categories).get();
          if (existingCategories.isEmpty) {
            await into(categories).insert(CategoriesCompanion(
              id: const Value('salary'),
              name: const Value('Зарплата'),
              icon: const Value('work'),
              isIncome: const Value(true),
            ));
            await into(categories).insert(CategoriesCompanion(
              id: const Value('freelance'),
              name: const Value('Фриланс'),
              icon: const Value('computer'),
              isIncome: const Value(true),
            ));
            await into(categories).insert(CategoriesCompanion(
              id: const Value('food'),
              name: const Value('Еда'),
              icon: const Value('restaurant'),
              isIncome: const Value(false),
            ));
            await into(categories).insert(CategoriesCompanion(
              id: const Value('transport'),
              name: const Value('Транспорт'),
              icon: const Value('directions_car'),
              isIncome: const Value(false),
            ));
            await into(categories).insert(CategoriesCompanion(
              id: const Value('health'),
              name: const Value('Здоровье'),
              icon: const Value('local_hospital'),
              isIncome: const Value(false),
            ));
            await into(categories).insert(CategoriesCompanion(
              id: const Value('entertainment'),
              name: const Value('Развлечения'),
              icon: const Value('movie'),
              isIncome: const Value(false),
            ));
          }
        }
      },
    );
  }

  // User methods
  Future<User> getUser(String id) => (select(users)..where((u) => u.id.equals(id))).getSingle();
  Future<List<User>> getAllUsers() => select(users).get();
  Future<int> insertUser(Insertable<User> user) => into(users).insert(user);
  Future<bool> updateUser(Insertable<User> user) => update(users).replace(user);
  Future<int> deleteUser(String id) => (delete(users)..where((u) => u.id.equals(id))).go();

  // Category methods
  Future<List<Category>> getCategories() => select(categories).get();
  Future<int> insertCategory(Insertable<Category> category) => into(categories).insert(category);
  Future<bool> updateCategory(Insertable<Category> category) => update(categories).replace(category);

  // Transaction methods
  Future<List<Transaction>> getTransactions() => select(transactions).get();
  Future<List<Transaction>> getTransactionsByUser(String userId) {
    return (select(transactions)..where((t) => t.userId.equals(userId))).get();
  }
  Future<int> insertTransaction(Insertable<Transaction> transaction) => into(transactions).insert(transaction);
  Future<bool> updateTransaction(Insertable<Transaction> transaction) => update(transactions).replace(transaction);
  Future<int> deleteTransaction(String id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Budget methods
  Future<List<Budget>> getBudgets() => select(budgets).get();
  Future<List<Budget>> getBudgetsByUser(String userId) {
    return (select(budgets)..where((b) => b.userId.equals(userId))).get();
  }
  Future<int> insertBudget(Insertable<Budget> budget) => into(budgets).insert(budget);
  Future<bool> updateBudget(Insertable<Budget> budget) => update(budgets).replace(budget);
  Future<int> deleteBudget(String id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  // FinancialGoal methods
  Future<List<FinancialGoal>> getFinancialGoals() => select(financialGoals).get();
  Future<List<FinancialGoal>> getFinancialGoalsByUser(String userId) {
    return (select(financialGoals)..where((g) => g.userId.equals(userId))).get();
  }
  Future<int> insertFinancialGoal(Insertable<FinancialGoal> goal) => into(financialGoals).insert(goal);
  Future<bool> updateFinancialGoal(Insertable<FinancialGoal> goal) => update(financialGoals).replace(goal);
  Future<int> deleteFinancialGoal(String id) => (delete(financialGoals)..where((g) => g.id.equals(id))).go();

  // Gamification methods
  Future<GamificationData> getGamification(String userId) => (select(gamification)..where((g) => g.userId.equals(userId))).getSingle();
  Future<int> insertGamification(Insertable<GamificationData> gamification) => into(this.gamification).insert(gamification);
  Future<bool> updateGamification(Insertable<GamificationData> gamification) => update(this.gamification).replace(gamification);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finlife.sqlite'));
    return NativeDatabase(file);
  });
}