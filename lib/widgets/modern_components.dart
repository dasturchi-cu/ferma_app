import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/modern_theme.dart';

// === MODERN CARD COMPONENT ===
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double? elevation;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: ModernTheme.spaceMD,
        vertical: ModernTheme.spaceSM,
      ),
      decoration: BoxDecoration(
        color: ModernTheme.cardColor,
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        boxShadow: elevation == 0 ? null : ModernTheme.softShadow,
        border: showBorder 
          ? Border.all(
              color: borderColor ?? ModernTheme.mediumGray, 
              width: 1,
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(ModernTheme.spaceMD),
            child: child,
          ),
        ),
      ),
    );
  }
}

// === STATUS CARDS ===
class SuccessCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SuccessCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: ModernTheme.spaceMD,
        vertical: ModernTheme.spaceSM,
      ),
      decoration: ModernTheme.successCardDecoration,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(ModernTheme.spaceMD),
        child: child,
      ),
    );
  }
}

class WarningCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const WarningCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: ModernTheme.spaceMD,
        vertical: ModernTheme.spaceSM,
      ),
      decoration: ModernTheme.warningCardDecoration,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(ModernTheme.spaceMD),
        child: child,
      ),
    );
  }
}

// === STAT CARD COMPONENT ===
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showTrend;
  final String? trendText;
  final bool isTrendPositive;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.showTrend = false,
    this.trendText,
    this.isTrendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(ModernTheme.spaceSM),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
              ),
              if (showTrend && trendText != null) ...[
                const SizedBox(width: ModernTheme.spaceXS),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ModernTheme.spaceSM - 2,
                      vertical: ModernTheme.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: (isTrendPositive 
                        ? ModernTheme.successColor 
                        : ModernTheme.errorColor
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                    ),
                    child: Text(
                      trendText!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isTrendPositive 
                          ? ModernTheme.successColor 
                          : ModernTheme.errorColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ModernTheme.spaceMD),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: ModernTheme.spaceXS),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModernTheme.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: ModernTheme.spaceXS),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ModernTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// === ACTION BUTTON COMPONENT ===
class ActionButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isCompact;

  const ActionButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(
              isCompact ? ModernTheme.spaceSM : ModernTheme.spaceMD,
            ),
            child: isCompact 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: ModernTheme.spaceSM),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ModernTheme.textPrimary,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ModernTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: ModernTheme.spaceSM),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ModernTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: ModernTheme.spaceXS),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ModernTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// === GRADIENT CARD COMPONENT ===
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: ModernTheme.spaceMD,
        vertical: ModernTheme.spaceSM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(ModernTheme.spaceMD),
            child: child,
          ),
        ),
      ),
    );
  }
}

// === MODERN INPUT FIELD ===
class ModernInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;

  const ModernInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModernTheme.textSecondary,
            ),
          ),
          const SizedBox(height: ModernTheme.spaceSM),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: ModernTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: ModernTheme.textTertiary)
              : null,
            suffixIcon: suffixIcon != null 
              ? IconButton(
                  onPressed: onSuffixPressed,
                  icon: Icon(suffixIcon, color: ModernTheme.textTertiary),
                )
              : null,
          ),
        ),
      ],
    );
  }
}

// === MODERN BUTTON COMPONENTS ===
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isFullWidth;
  final ModernButtonType type;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isFullWidth = false,
    this.type = ModernButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    switch (type) {
      case ModernButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonChild(),
        );
        break;
      case ModernButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonChild(),
        );
        break;
      case ModernButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonChild(),
        );
        break;
    }

    return isFullWidth 
      ? SizedBox(width: double.infinity, child: button)
      : button;
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: ModernTheme.spaceSM),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

enum ModernButtonType { primary, secondary, text }

// === SECTION HEADER ===
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernTheme.spaceMD,
        vertical: ModernTheme.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: ModernTheme.spaceXS),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ModernTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// === MODERN APP BAR ===
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ?? (showBackButton 
        ? IconButton(
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios),
          )
        : null),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ModernTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
      backgroundColor: ModernTheme.surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// === MODERN BOTTOM SHEET ===
class ModernBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const ModernBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernBottomSheet(
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ModernTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ModernTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: ModernTheme.spaceSM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ModernTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spaceMD,
              vertical: ModernTheme.spaceSM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Flexible(child: child),
          
          // Actions
          if (actions != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(ModernTheme.spaceMD),
              child: Row(
                children: actions!
                  .map((action) => Expanded(child: action))
                  .toList(),
              ),
            ),
          ],
          
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}