import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Circular avatar with initials/emoji, optionally wrapped in an amber ring.
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
        gradient: ring
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CG.line2, CG.bg3],
              ),
        color: ring ? CG.bg2 : null,
        border: ring ? null : Border.all(color: CG.line2),
      ),
      child: Text(
        label,
        style: T.heading(size * 0.4, weight: FontWeight.w800),
      ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: CG.accentGradient,
      ),
      child: inner,
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

/// The CockroachGram top app bar — brand logo + search / chat / bell actions.
class AppHeader extends StatelessWidget {
  final VoidCallback? onSearch;
  final VoidCallback? onChat;
  final VoidCallback? onBell;
  final bool unread;
  const AppHeader({super.key, this.onSearch, this.onChat, this.onBell, this.unread = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: CG.accentGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: CG.glow(blur: 12, y: 4),
            ),
            child: const Text('🪳', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              style: T.display(26),
              children: const [
                TextSpan(text: 'Cockroach'),
                TextSpan(text: 'Gram', style: TextStyle(color: CG.accent2)),
              ],
            ),
          ),
          const Spacer(),
          IconBtn(Icons.search, onTap: onSearch),
          const SizedBox(width: 4),
          IconBtn(Icons.chat_bubble_outline, onTap: onChat),
          const SizedBox(width: 4),
          IconBtn(Icons.notifications_none_rounded, dot: unread, onTap: onBell),
        ],
      ),
    );
  }
}

/// Filled-gradient or ghost button matching the `.btn` styles.
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: primary ? CG.accentGradient : null,
            color: primary ? null : CG.accent2.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: primary ? null : Border.all(color: CG.line2),
            boxShadow: primary ? CG.glow() : null,
          ),
          child: Text(
            label,
            style: T.heading(14, weight: FontWeight.w700, spacingEm: 0.02)
                .copyWith(color: primary ? CG.bg : CG.text),
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
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              GestureDetector(
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: i == selected
                              ? CG.accent2.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          labels[i],
                          style: T.body(
                            13,
                            weight: FontWeight.w600,
                            color: i == selected ? CG.text : CG.text3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      LayoutBuilder(
                        builder: (context, _) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 2,
                          width: i == selected ? 36 : 0,
                          decoration: BoxDecoration(
                            color: CG.accent2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 84,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: CG.bg.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(color: CG.accent2.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            children: [
              _navItem(0, 'Home', Icons.home_rounded),
              _navItem(1, 'Trends', Icons.trending_up_rounded),
              _composeItem(),
              _navItem(3, 'Alerts', Icons.notifications_none_rounded, dot: true),
              _navItem(4, 'Profile', Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon, {bool dot = false}) {
    final isActive = active == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onNav(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: isActive ? CG.accent2 : CG.text3),
                if (dot)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CG.accent2,
                        boxShadow: CG.glow(blur: 6, y: 0),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: T.body(10,
                  weight: FontWeight.w600,
                  color: isActive ? CG.accent2 : CG.text3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composeItem() {
    return Expanded(
      child: GestureDetector(
        onTap: onCompose,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 14),
          decoration: BoxDecoration(
            gradient: CG.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: CG.glow(blur: 20),
          ),
          child: const Icon(Icons.add, size: 22, color: CG.bg),
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
