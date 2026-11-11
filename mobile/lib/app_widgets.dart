import 'package:flutter/material.dart';

abstract final class LiveStockColors {
  static const forest = Color(0xFF173C2C);
  static const leaf = Color(0xFF79A365);
  static const lime = Color(0xFFC9E68C);
  static const canvas = Color(0xFFF3F5F0);
  static const ink = Color(0xFF1E2A23);
  static const muted = Color(0xFF77827B);
  static const line = Color(0xFFE3E8E1);
  static const amber = Color(0xFFE5AD56);
  static const coral = Color(0xFFC7674C);
}

String formatGhs(double value) => 'GH₵ ${value.toStringAsFixed(2)}';

String formatFarmDate(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return 'Date unavailable';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class LiveStockPanel extends StatelessWidget {
  const LiveStockPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: LiveStockColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.eyebrow, required this.title, required this.subtitle});

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: text.labelSmall?.copyWith(color: LiveStockColors.leaf, fontWeight: FontWeight.w800, letterSpacing: 1.15)),
        const SizedBox(height: 4),
        Text(title, style: text.headlineSmall?.copyWith(color: LiveStockColors.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: text.bodySmall?.copyWith(color: LiveStockColors.muted, height: 1.4)),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: LiveStockColors.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted, height: 1.4)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.icon, this.tint = LiveStockColors.leaf});

  final String label;
  final String value;
  final IconData? icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return LiveStockPanel(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: tint),
            const SizedBox(height: 10),
          ],
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: LiveStockColors.ink)),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted)),
        ],
      ),
    );
  }
}

class LocalOnlyNote extends StatelessWidget {
  const LocalOnlyNote({super.key, this.message = 'Saved on this device. Shared accounts and cloud sync are not connected yet.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 15, color: LiveStockColors.muted),
        const SizedBox(width: 7),
        Expanded(child: Text(message, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted, height: 1.45))),
      ],
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 25, color: LiveStockColors.leaf),
          const SizedBox(height: 9),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted, height: 1.45)),
        ],
      ),
    );
  }
}