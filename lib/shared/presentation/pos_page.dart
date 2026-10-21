import 'package:flutter/material.dart';

import 'cafe_colors.dart';

class PosPage extends StatelessWidget {
  const PosPage({
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.isWorking = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool isWorking;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CafeColors.ivory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Container(
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: CafeColors.ivory,
                border: Border(
                  bottom: BorderSide(color: CafeColors.outlineSoft),
                ),
              ),
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: CafeColors.muted),
                          ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 12),
                    ...actions,
                  ],
                ],
              ),
            ),
          ),
          if (isWorking) const LinearProgressIndicator(minHeight: 3),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class PosSurface extends StatelessWidget {
  const PosSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CafeColors.outlineSoft),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PosStatusPill extends StatelessWidget {
  const PosStatusPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
