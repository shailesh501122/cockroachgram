import 'package:flutter/material.dart';
import '../theme.dart';

/// Circular avatar with initials/emoji. Optionally wrapped in a 2px amber ring.
class Avatar extends StatelessWidget {
  final String label;
  final double size;
  final bool ring;
  const Avatar(this.label, {super.key, this.size = 38, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CG.bg2,
        border: ring ? null : Border.all(color: CG.line2),
      ),
      child: Text(
        label,
        style: T.body(size * 0.38, weight: FontWeight.w600, height: 1),
      ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CG.accent2,
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CG.bg,
        ),
        padding: const EdgeInsets.all(2),
        child: inner,
      ),
    );
  }
}

/// 38×38 (configurable) rounded-square icon button with an optional amber dot.
class IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool dot;
  final Color? iconColor;
  final Color? background;
  final VoidCallback? onTap;
  const IconBtn(
    this.icon, {
    super.key,
    this.size = 38,
    this.iconSize = 18,
    this.dot = false,
    this.iconColor,
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? CG.accent2.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: background != null ? null : Border.all(color: CG.line),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor ?? CG.text),
            if (dot)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CG.accent2,
                    boxShadow: CG.glow(blur: 8, y: 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The CockroachGram top app bar — clean Instagram-style:
/// wordmark on the left, naked action icons on the right (no boxes).
class AppHeader extends StatelessWidget {
  final VoidCallback? onSearch;
  final VoidCallback? onChat;
  final VoidCallback? onBell;
  final bool unread;
  const AppHeader({super.key, this.onSearch, this.onChat, this.onBell, this.unread = true});

  Widget _navIcon(IconData icon, {VoidCallback? onTap, bool dot = false}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 24, color: CG.text),
              if (dot)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CG.accent2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              style: T.heading(22,
                  weight: FontWeight.w700, letterSpacing: -0.5),
              children: const [
                TextSpan(text: 'Cockroach'),
                TextSpan(text: 'Gram', style: TextStyle(color: CG.accent2)),
              ],
            ),
          ),
          const Spacer(),
          _navIcon(Icons.search, onTap: onSearch),
          _navIcon(Icons.chat_bubble_outline, onTap: onChat),
          _navIcon(Icons.favorite_border, dot: unread, onTap: onBell),
        ],
      ),
    );
  }
}

/// Flat amber primary or outlined ghost button — Instagram-clean.
class CGButton extends StatelessWidget {
  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback? onTap;
  const CGButton(
    this.label, {
    super.key,
    this.primary = true,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? CG.accent2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: primary ? null : Border.all(color: CG.line2),
          ),
          child: Text(
            label,
            style: T.body(14,
                weight: FontWeight.w600,
                color: primary ? CG.bg : CG.text,
                letterSpacing: 0.1),
          ),
        ),
      ),
    );
  }
}

/// Horizontally-scrolling pill tab row with the growing amber underline.
class CGTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const CGTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CG.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 1.5,
                        color:
                            i == selected ? CG.accent2 : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: T.body(
                      13,
                      weight:
                          i == selected ? FontWeight.w600 : FontWeight.w500,
                      color: i == selected ? CG.text : CG.text3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A "page-head" block — big Bebas title + sub-line + trailing action.
class PageHead extends StatelessWidget {
  final String title;
  final String sub;
  final Widget? trailing;
  const PageHead({super.key, required this.title, required this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.display(32)),
                const SizedBox(height: 2),
                Text(sub, style: T.body(12, color: CG.text3)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Glassmorphism bottom navigation with the central gradient compose button.
class CGBottomNav extends StatelessWidget {
  final int active; // 0 feed, 1 trending, 3 alerts, 4 profile
  final ValueChanged<int> onNav;
  final VoidCallback onCompose;
  const CGBottomNav({
    super.key,
    required this.active,
    required this.onNav,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
      decoration: const BoxDecoration(
        color: CG.bg,
        border: Border(top: BorderSide(color: CG.line)),
      ),
      child: Row(
        children: [
          _navItem(0, 'Home', Icons.home_outlined, Icons.home_rounded),
          _navItem(1, 'Trends', Icons.trending_up_rounded, Icons.trending_up_rounded),
          _composeItem(),
          _navItem(3, 'Alerts', Icons.favorite_border, Icons.favorite, dot: true),
          _navItem(4, 'Profile', Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _navItem(int index, String _, IconData iconOff, IconData iconOn,
      {bool dot = false}) {
    final isActive = active == index;
    final icon = isActive ? iconOn : iconOff;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onNav(index),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 26, color: isActive ? CG.accent2 : CG.text),
              if (dot)
                Positioned(
                  top: -1,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CG.accent2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composeItem() {
    return Expanded(
      child: GestureDetector(
        onTap: onCompose,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CG.accent2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 22, color: CG.bg),
          ),
        ),
      ),
    );
  }
}

/// Empty-state caption used at the bottom of feeds.
class FeedCaption extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const FeedCaption(this.text,
      {super.key, this.padding = const EdgeInsets.fromLTRB(20, 40, 20, 100)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: T.body(12, color: CG.text3),
        ),
      ),
    );
  }
}
