import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/modern_theme.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: ModernTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernTheme.spaceLG,
            vertical: ModernTheme.spaceSM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Asosiy',
                index: 0,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _buildNavItem(
                icon: Icons.people_rounded,
                label: 'Mijozlar',
                index: 1,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _buildNavItem(
                icon: Icons.egg_rounded,
                label: 'Tuxum',
                index: 2,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _buildNavItem(
                icon: Icons.analytics_rounded,
                label: 'Hisobot',
                index: 3,
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Qarzlar',
                index: 4,
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.spaceSM,
          vertical: ModernTheme.spaceXS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            ? ModernTheme.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                  ? ModernTheme.primaryGreen
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected 
                  ? ModernTheme.textOnPrimary
                  : ModernTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                  ? ModernTheme.primaryGreen
                  : ModernTheme.textTertiary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}