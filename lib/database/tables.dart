import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get name => text().named('name')();
  TextColumn get email => text().named('email')();
  RealColumn get monthlyIncome => real().named('monthly_income')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get gender => text().named('gender').nullable()();
  IntColumn get age => integer().named('age').nullable()();
  TextColumn get financialGoal => text().named('financial_goal').nullable()();

  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [];
}

class Categories extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get name => text().named('name')();
  TextColumn get icon => text().named('icon')();
  BoolColumn get isIncome => boolean().named('is_income')();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get userId => text().named('user_id').references(Users, #id)();
  TextColumn get categoryId => text().named('category_id').references(Categories, #id)();
  TextColumn get description => text().named('description')();
  RealColumn get amount => real().named('amount')();
  TextColumn get type => text().named('type')();
  DateTimeColumn get date => dateTime().named('date')();
  BoolColumn get isRecurring => boolean().named('is_recurring').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get userId => text().named('user_id').references(Users, #id)();
  TextColumn get categoryId => text().named('category_id').references(Categories, #id)();
  TextColumn get name => text().named('name')();
  RealColumn get amount => real().named('amount')();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}

class FinancialGoals extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get userId => text().named('user_id').references(Users, #id)();
  TextColumn get title => text().named('title')();
  TextColumn get description => text().named('description')();
  RealColumn get targetAmount => real().named('target_amount')();
  RealColumn get currentAmount => real().named('current_amount')();
  DateTimeColumn get targetDate => dateTime().named('target_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Gamification extends Table {
  TextColumn get id => text().named('id').customConstraint('UNIQUE NOT NULL')();
  TextColumn get userId => text().named('user_id').references(Users, #id)();
  IntColumn get streak => integer().named('streak')();
  TextColumn get achievements => text().named('achievements')();
  DateTimeColumn get lastActivity => dateTime().named('last_activity')();
  
  @override
  Set<Column> get primaryKey => {id};
}