import 'package:flutter/material.dart';

/// Shared card used by every metric (tempo, shoulder, hip, head).
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.valueText,
    this.bandLabel,
    this.subtitle,
    super.key,
  });

  final String title;
  final String valueText;
  final String? bandLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bandColor = _bandColor(theme, bandLabel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.labelLarge),
                ),
                if (bandLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bandColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bandLabel!,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(valueText, style: theme.textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  static Color _bandColor(ThemeData theme, String? label) {
    switch (label) {
      case 'good':
        return Colors.green.shade600;
      case 'fair':
        return Colors.orange.shade700;
      case 'off':
        return Colors.red.shade600;
      default:
        return theme.colorScheme.outline;
    }
  }
}
