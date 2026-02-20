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
    'Еда': CategoryInfo(
      name: 'Еда',
      emoji: '🍔',
      color: const Color(0xFF4CAF50),
    ),
    'Транспорт': CategoryInfo(
      name: 'Транспорт',
      emoji: '🚗',
      color: const Color(0xFF2196F3),
    ),
    'Здоровье': CategoryInfo(
      name: 'Здоровье',
      emoji: '💊',
      color: const Color(0xFFF44336),
    ),
    'Развлечения': CategoryInfo(
      name: 'Развлечения',
      emoji: '🎬',
      color: const Color(0xFFFF9800),
    ),
    'Зарплата': CategoryInfo(
      name: 'Зарплата',
      emoji: '💰',
      color: const Color(0xFF9C27B0),
    ),
    'Кафе': CategoryInfo(
      name: 'Кафе',
      emoji: '☕',
      color: const Color(0xFF795548),
    ),
    'Фриланс': CategoryInfo(
      name: 'Фриланс',
      emoji: '💻',
      color: const Color(0xFF607D8B),
    ),
    'Подарок': CategoryInfo(
      name: 'Подарок',
      emoji: '🎁',
      color: const Color(0xFFE91E63),
    ),
    'Другое': CategoryInfo(
      name: 'Другое',
      emoji: '📦',
      color: const Color(0xFF9E9E9E),
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