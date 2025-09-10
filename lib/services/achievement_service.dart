import 'dart:math';
import '../models/farm.dart';

enum AchievementCategory {
  consistency,
  production,
  health,
  business,
  milestone,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final AchievementCategory category;
  final DateTime unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.category,
    DateTime? unlockedAt,
    this.isUnlocked = false,
  }) : unlockedAt = unlockedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'category': category.name,
      'unlockedAt': unlockedAt.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      points: json['points'],
      category: AchievementCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => AchievementCategory.milestone,
      ),
      unlockedAt: DateTime.parse(json['unlockedAt']),
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}

class AchievementProgress {
  final int totalPoints;
  final int currentLevel;
  final int nextLevelPoints;
  final int consecutiveDays;
  final int totalEggs;
  final double totalProfit;
  final int healthyDays;
  final List<Achievement> achievements;

  AchievementProgress({
    required this.totalPoints,
    required this.currentLevel,
    required this.nextLevelPoints,
    required this.consecutiveDays,
    required this.totalEggs,
    required this.totalProfit,
    required this.healthyDays,
    required this.achievements,
  });
}

class AchievementService {
  static List<Achievement> _predefinedAchievements = [
    // Consistency Achievements
    Achievement(
      id: 'week_streak',
      title: '🔥 Bir hafta ketma-ket!',
      description: '7 kun ketma-ket ma\'lumot kiritdingiz',
      icon: '🔥',
      points: 100,
      category: AchievementCategory.consistency,
    ),
    Achievement(
      id: 'month_streak',
      title: '👑 Bir oy champion!',
      description: '30 kun ketma-ket ferma ma\'lumotlarini kiritdingiz',
      icon: '👑',
      points: 500,
      category: AchievementCategory.consistency,
    ),
    Achievement(
      id: 'year_streak',
      title: '💎 Bir yil ustozi!',
      description: '365 kun ketma-ket ferma ma\'lumotlarini kiritdingiz',
      icon: '💎',
      points: 2000,
      category: AchievementCategory.consistency,
    ),

    // Production Achievements
    Achievement(
      id: 'eggs_100',
      title: '🥚 Yuz fletka!',
      description: 'Jami 100 fletka tuxum yig\'dingiz',
      icon: '🥚',
      points: 50,
      category: AchievementCategory.production,
    ),
    Achievement(
      id: 'eggs_1000',
      title: '🥚 Ming fletka!',
      description: 'Jami 1000 fletka tuxum yig\'dingiz',
      icon: '🥚',
      points: 200,
      category: AchievementCategory.production,
    ),
    Achievement(
      id: 'eggs_10000',
      title: '🥚 O\'n ming fletka!',
      description: 'Jami 10,000 fletka tuxum yig\'dingiz',
      icon: '🥚',
      points: 1000,
      category: AchievementCategory.production,
    ),

    // Best Day Achievements
    Achievement(
      id: 'best_day_20',
      title: '⭐ Yaxshi kun!',
      description: 'Bir kunda 20 fletka tuxum yig\'dingiz',
      icon: '⭐',
      points: 75,
      category: AchievementCategory.production,
    ),
    Achievement(
      id: 'best_day_40',
      title: '🌟 Eng yaxshi kun!',
      description: 'Bir kunda 40 fletka tuxum yig\'dingiz',
      icon: '🌟',
      points: 150,
      category: AchievementCategory.production,
    ),
    Achievement(
      id: 'best_day_60',
      title: '💫 Mukammal kun!',
      description: 'Bir kunda 60 fletka tuxum yig\'dingiz',
      icon: '💫',
      points: 300,
      category: AchievementCategory.production,
    ),

    // Health Achievements
    Achievement(
      id: 'no_deaths_week',
      title: '😊 Bir hafta sog\'lom!',
      description: 'Bu hafta hech bir tovuq o\'lmadi',
      icon: '😊',
      points: 150,
      category: AchievementCategory.health,
    ),
    Achievement(
      id: 'no_deaths_month',
      title: '😊 Barcha tovuqlar sog\'!',
      description: 'Bu oy hech bir tovuq o\'lmadi',
      icon: '😊',
      points: 300,
      category: AchievementCategory.health,
    ),

    // Business Achievements
    Achievement(
      id: 'profit_100k',
      title: '💰 Birinchi yuz ming!',
      description: 'Bu oy 100,000 som foyda qildingiz',
      icon: '💰',
      points: 200,
      category: AchievementCategory.business,
    ),
    Achievement(
      id: 'profit_million',
      title: '💰 Millioner!',
      description: 'Bu oy 1 million som foyda qildingiz',
      icon: '💰',
      points: 1000,
      category: AchievementCategory.business,
    ),
    Achievement(
      id: 'customers_10',
      title: '👥 O\'n mijoz!',
      description: '10 ta doimiy mijozingiz bor',
      icon: '👥',
      points: 150,
      category: AchievementCategory.business,
    ),
    Achievement(
      id: 'customers_50',
      title: '👥 Ellilik jamoat!',
      description: '50 ta doimiy mijozingiz bor',
      icon: '👥',
      points: 500,
      category: AchievementCategory.business,
    ),

    // Milestone Achievements
    Achievement(
      id: 'first_farm',
      title: '🏡 Birinchi ferma!',
      description: 'Ferma App ga xush kelibsiz!',
      icon: '🏡',
      points: 25,
      category: AchievementCategory.milestone,
    ),
    Achievement(
      id: 'level_10',
      title: '🏅 O\'ninchi level!',
      description: '10-levelga yetib keldingiz',
      icon: '🏅',
      points: 250,
      category: AchievementCategory.milestone,
    ),
    Achievement(
      id: 'perfect_week',
      title: '⚡ Mukammal hafta!',
      description:
          'Bir hafta davomida har kuni o\'rtachadan ko\'p tuxum yig\'dingiz',
      icon: '⚡',
      points: 400,
      category: AchievementCategory.production,
    ),
  ];

  static List<Achievement> checkAchievements(
    Farm farm,
    List<Achievement> existingAchievements,
  ) {
    List<Achievement> newAchievements = [];
    List<String> existingIds = existingAchievements.map((a) => a.id).toList();

    // Check each predefined achievement
    for (Achievement achievement in _predefinedAchievements) {
      if (!existingIds.contains(achievement.id)) {
        if (_checkAchievementCondition(achievement, farm)) {
          newAchievements.add(
            achievement.copyWith(isUnlocked: true, unlockedAt: DateTime.now()),
          );
        }
      }
    }

    return newAchievements;
  }

  static bool _checkAchievementCondition(Achievement achievement, Farm farm) {
    switch (achievement.id) {
      // Consistency achievements
      case 'week_streak':
        return _getConsecutiveDays(farm) >= 7;
      case 'month_streak':
        return _getConsecutiveDays(farm) >= 30;
      case 'year_streak':
        return _getConsecutiveDays(farm) >= 365;

      // Production achievements
      case 'eggs_100':
        return _getTotalEggs(farm) >= 100;
      case 'eggs_1000':
        return _getTotalEggs(farm) >= 1000;
      case 'eggs_10000':
        return _getTotalEggs(farm) >= 10000;

      // Best day achievements
      case 'best_day_20':
        return _getMaxEggsInDay(farm) >= 20;
      case 'best_day_40':
        return _getMaxEggsInDay(farm) >= 40;
      case 'best_day_60':
        return _getMaxEggsInDay(farm) >= 60;

      // Health achievements
      case 'no_deaths_week':
        return _hasNoDeathsThisWeek(farm);
      case 'no_deaths_month':
        return _hasNoDeathsThisMonth(farm);

      // Business achievements
      case 'profit_100k':
        return _getMonthlyProfit(farm) >= 100000;
      case 'profit_million':
        return _getMonthlyProfit(farm) >= 1000000;
      case 'customers_10':
        return farm.customers.length >= 10;
      case 'customers_50':
        return farm.customers.length >= 50;

      // Milestone achievements
      case 'first_farm':
        return true; // Always unlocked for new users
      case 'level_10':
        return _calculateLevel(farm) >= 10;
      case 'perfect_week':
        return _hasPerfectWeek(farm);

      default:
        return false;
    }
  }

  // Progress tracking
  static AchievementProgress getProgress(
    Farm farm,
    List<Achievement> achievements,
  ) {
    int totalPoints = _calculateTotalPoints(achievements);

    return AchievementProgress(
      totalPoints: totalPoints,
      currentLevel: _calculateLevel(farm),
      nextLevelPoints: _getNextLevelPoints(totalPoints),
      consecutiveDays: _getConsecutiveDays(farm),
      totalEggs: _getTotalEggs(farm),
      totalProfit: _getMonthlyProfit(farm),
      healthyDays: _getHealthyDays(farm),
      achievements: achievements,
    );
  }

  // Helper methods
  static int _calculateTotalPoints(List<Achievement> achievements) {
    return achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.points);
  }

  static int _calculateLevel(Farm farm) {
    int totalPoints = farm.farmStats['totalPoints'] ?? 0;
    return (totalPoints / 1000).floor() + 1;
  }

  static int _getNextLevelPoints(int currentPoints) {
    int currentLevel = (currentPoints / 1000).floor() + 1;
    return currentLevel * 1000;
  }

  static int _getConsecutiveDays(Farm farm) {
    // This would need to track consecutive days in real implementation
    return farm.farmStats['consecutiveDays'] ?? 1;
  }

  static int _getTotalEggs(Farm farm) {
    return farm.farmStats['totalEggs'] ?? 0;
  }

  static int _getMaxEggsInDay(Farm farm) {
    return farm.farmStats['maxEggsInDay'] ?? 0;
  }

  static double _getMonthlyProfit(Farm farm) {
    return (farm.farmStats['monthlyProfit'] ?? 0).toDouble();
  }

  static int _getHealthyDays(Farm farm) {
    return farm.farmStats['healthyDays'] ?? 0;
  }

  static bool _hasNoDeathsThisWeek(Farm farm) {
    int weeklyDeaths = farm.farmStats['weeklyDeaths'] ?? 0;
    return weeklyDeaths == 0;
  }

  static bool _hasNoDeathsThisMonth(Farm farm) {
    int monthlyDeaths = farm.farmStats['monthlyDeaths'] ?? 0;
    return monthlyDeaths == 0;
  }

  static bool _hasPerfectWeek(Farm farm) {
    // Check if all 7 days this week had above-average egg production
    List<int> weeklyEggs = farm.farmStats['weeklyEggs'] ?? [];
    int avgEggs = farm.farmStats['averageEggs'] ?? 0;

    if (weeklyEggs.length < 7) return false;

    return weeklyEggs.every((eggs) => eggs > avgEggs);
  }
}

// Extension to add copyWith method to Achievement
extension AchievementExtension on Achievement {
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? points,
    AchievementCategory? category,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      points: points ?? this.points,
      category: category ?? this.category,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
