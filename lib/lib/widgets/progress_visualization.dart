import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AchievementProgress {
  final int totalPoints;
  final int currentLevel;
  final int nextLevelPoints;
  final int consecutiveDays;
  final int totalEggs;
  final double totalProfit;
  final int healthyDays;

  AchievementProgress({
    required this.totalPoints,
    required this.currentLevel,
    required this.nextLevelPoints,
    required this.consecutiveDays,
    required this.totalEggs,
    required this.totalProfit,
    required this.healthyDays,
  });
}

class ProgressVisualization extends StatelessWidget {
  final AchievementProgress progress;

  const ProgressVisualization({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              AppTheme.primaryLight.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level and Progress
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${progress.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.totalPoints} ball',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar to next level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keyingi level uchun: ${progress.nextLevelPoints - progress.totalPoints} ball',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.totalPoints / progress.nextLevelPoints,
                  backgroundColor: AppTheme.textLight.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  minHeight: 6,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '🔥',
                    '${progress.consecutiveDays}',
                    'Kun ketma-ket',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '🥚',
                    '${progress.totalEggs}',
                    'Jami tuxum',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '💰',
                    '${(progress.totalProfit / 1000).toStringAsFixed(1)}k',
                    'Jami foyda (som)',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '😊',
                    '${progress.healthyDays}',
                    'Sog\'lom kunlar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 