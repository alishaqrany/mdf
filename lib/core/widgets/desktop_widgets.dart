import 'package:flutter/material.dart';

import '../../core/platform/platform_info.dart';

/// Breadcrumb-style navigation trail for web/desktop.
///
/// Shows the current page hierarchy. On mobile it's hidden.
class WebBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const WebBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isMobile || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            if (i < items.length - 1)
              InkWell(
                onTap: items[i].onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )
            else
              Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

/// Hover-aware card for desktop — elevates on hover.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isHovered && !PlatformInfo.isMobile
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        border: Border.all(
          color: _isHovered
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (PlatformInfo.isMobile) {
      return GestureDetector(onTap: widget.onTap, child: card);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

/// Context menu wrapper for desktop right-click.
class DesktopContextMenu extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String value)? onSelected;

  const DesktopContextMenu({
    super.key,
    required this.child,
    required this.menuItems,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isMobile) return child;

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx + 1,
            details.globalPosition.dy + 1,
          ),
          items: menuItems,
        );
        if (result != null) onSelected?.call(result);
      },
      child: child,
    );
  }
}
