import 'package:flutter/material.dart';

class InfoHeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? contentColor;
  final Color? borderColor;

  const InfoHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.gradient,
    this.backgroundColor,
    this.titleColor,
    this.contentColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Gradient? bg = gradient ?? null;
    final Color bgColor = backgroundColor ?? (bg == null ? scheme.surface : scheme.primary);
    final Color tColor = titleColor ?? (bg == null ? scheme.primary : Colors.white);
    final Color cColor = contentColor ?? (bg == null ? scheme.onSurface : Colors.white);
    final Color? bColor = borderColor ?? (bg == null ? scheme.outline.withOpacity(0.12) : null);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg == null ? bgColor : null,
        gradient: bg,
        borderRadius: BorderRadius.circular(12),
        border: bColor != null ? Border.all(color: bColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Baseline(
                baseline: 22,
                baselineType: TextBaseline.alphabetic,
                child: Icon(icon, color: tColor, size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: tColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: TextStyle(color: cColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
