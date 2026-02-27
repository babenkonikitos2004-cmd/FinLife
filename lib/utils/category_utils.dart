import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final String emoji;
  final Color color;

  CategoryInfo({
    required this.name,
    required this.emoji,
    required this.color,
  });
}

class CategoryUtils {
  static final Map<String, CategoryInfo> categoryMap = {
    'food': CategoryInfo(
      name: 'Еда',
      emoji: '🍔',
      color: const Color(0xFF4CAF50),
    ),
    'Еда': CategoryInfo(
      name: 'Еда',
      emoji: '🍔',
      color: const Color(0xFF4CAF50),
    ),
    'transport': CategoryInfo(
      name: 'Транспорт',
      emoji: '🚗',
      color: const Color(0xFF2196F3),
    ),
    'Транспорт': CategoryInfo(
      name: 'Транспорт',
      emoji: '🚗',
      color: const Color(0xFF2196F3),
    ),
    'health': CategoryInfo(
      name: 'Здоровье',
      emoji: '💊',
      color: const Color(0xFFF44336),
    ),
    'Здоровье': CategoryInfo(
      name: 'Здоровье',
      emoji: '💊',
      color: const Color(0xFFF44336),
    ),
    'entertainment': CategoryInfo(
      name: 'Развлечения',
      emoji: '🎬',
      color: const Color(0xFFFF9800),
    ),
    'Развлечения': CategoryInfo(
      name: 'Развлечения',
      emoji: '🎬',
      color: const Color(0xFFFF9800),
    ),
    'clothing': CategoryInfo(
      name: 'Одежда',
      emoji: '👕',
      color: const Color(0xFF9C27B0),
    ),
    'Одежда': CategoryInfo(
      name: 'Одежда',
      emoji: '👕',
      color: const Color(0xFF9C27B0),
    ),
    'other': CategoryInfo(
      name: 'Другое',
      emoji: '📦',
      color: const Color(0xFF9E9E9E),
    ),
    'Другое': CategoryInfo(
      name: 'Другое',
      emoji: '📦',
      color: const Color(0xFF9E9E9E),
    ),
    'salary': CategoryInfo(
      name: 'Зарплата',
      emoji: '💰',
      color: const Color(0xFF9C27B0),
    ),
    'Зарплата': CategoryInfo(
      name: 'Зарплата',
      emoji: '💰',
      color: const Color(0xFF9C27B0),
    ),
    'cafe': CategoryInfo(
      name: 'Кафе',
      emoji: '☕',
      color: const Color(0xFF795548),
    ),
    'Кафе': CategoryInfo(
      name: 'Кафе',
      emoji: '☕',
      color: const Color(0xFF795548),
    ),
    'freelance': CategoryInfo(
      name: 'Фриланс',
      emoji: '💻',
      color: const Color(0xFF607D8B),
    ),
    'Фриланс': CategoryInfo(
      name: 'Фриланс',
      emoji: '💻',
      color: const Color(0xFF607D8B),
    ),
    'gift': CategoryInfo(
      name: 'Подарок',
      emoji: '🎁',
      color: const Color(0xFFE91E63),
    ),
    'Подарок': CategoryInfo(
      name: 'Подарок',
      emoji: '🎁',
      color: const Color(0xFFE91E63),
    ),
  };

  static CategoryInfo getCategoryInfo(String categoryName) {
    return categoryMap[categoryName] ?? 
           CategoryInfo(
             name: categoryName,
             emoji: '📦',
             color: const Color(0xFF9E9E9E),
           );
  }
}