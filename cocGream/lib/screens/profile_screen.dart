import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/auth_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Screen 06 — the member profile with cover, stats and post grid.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  const ProfileScreen({super.key, this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  static const _gridEmojis = [
    '🪳', '📣', '🗳️', '🇮🇳', '✊', '📊', '🎤', '🔥', '📰', '👥', '💬', '📍',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: CG.accent2));
    }
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ===== Cover + avatar =====
              SizedBox(
                height: 182,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const _Cover(),
                    Positioned(
                      top: 98,
                      left: 20,
                      child: Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: CG.accentGradient,
                          boxShadow: CG.glow(blur: 32, y: 12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CG.bg2,
                            border: Border.all(color: CG.bg, width: 2),
                          ),
                          child: Text(user.initials, style: T.display(38)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ===== Identity =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text(user.name, style: T.heading(22))),
                        if (user.verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: CG.accentGradient,
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: CG.bg),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.handle, style: T.body(13, color: CG.text3)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CG.accent2.withValues(alpha: 0.1),
                        border: Border.all(
                            color: CG.accent2.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🪳 Cockroach Member #${user.memberNo}',
                        style: T.heading(11,
                            weight: FontWeight.w700,
                            color: CG.accent2,
                            spacingEm: 0.05),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.bio, style: T.body(14, height: 1.45)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _metaItem(Icons.location_on_outlined, user.state),
                        _metaItem(Icons.person_outline, user.joinedLabel),
                      ],
                    ),
                  ],
                ),
              ),
              // ===== Stats =====
              Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CG.line),
                    bottom: BorderSide(color: CG.line),
                  ),
                ),
                child: Row(
                  children: [
                    _stat(fmt(user.stats.posts), 'Posts'),
                    _stat(fmt(user.stats.followers), 'Followers'),
                    _stat(fmt(user.stats.following), 'Following'),
                    _stat(fmt(user.stats.roars), 'Roars 🪳', color: CG.accent2),
                  ],
                ),
              ),
              // ===== Actions =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    const Expanded(child: CGButton('Edit Profile')),
                    const SizedBox(width: 8),
                    const Expanded(child: CGButton('Share', primary: false)),
                    if (widget.onSignOut != null) ...[
                      const SizedBox(width: 8),
                      IconBtn(
                        Icons.logout_rounded,
                        size: 46,
                        iconSize: 18,
                        onTap: widget.onSignOut,
                      ),
                    ],
                  ],
                ),
              ),
              // ===== Tab row =====
              Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CG.line)),
                ),
                child: Row(
                  children: [
                    _profileTab(0, 'Posts', Icons.grid_on),
                    _profileTab(1, 'Media', Icons.image_outlined),
                    _profileTab(2, 'Saved', Icons.bookmark_border),
                  ],
                ),
              ),
              // ===== Grid =====
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) => _GridCell(
                    emoji: _gridEmojis[i],
                    variant: i % 3,
                    pinned: i == 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: CG.text3),
          const SizedBox(width: 4),
          Text(text, style: T.body(12, color: CG.text3)),
        ],
      );

  Widget _stat(String num, String label, {Color color = CG.text}) => Expanded(
        child: Column(
          children: [
            Text(num, style: T.display(22, color: color)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: T.body(10, color: CG.text3, letterSpacing: 0.8)),
          ],
        ),
      );

  Widget _profileTab(int index, String label, IconData icon) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CG.accent2 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: active ? CG.accent2 : CG.text3),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: T.heading(11,
                    weight: FontWeight.w700,
                    color: active ? CG.accent2 : CG.text3,
                    spacingEm: 0.05),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cover banner with a faint rotated cockroach texture.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1D05), CG.bg, Color(0xFF3A2710)],
                  stops: [0, 0.6, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, 0),
                  radius: 0.8,
                  colors: [
                    CG.accent2.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -12 * math.pi / 180,
                  child: Transform.scale(
                    scale: 1.2,
                    child: Opacity(
                      opacity: 0.07,
                      child: OverflowBox(
                        maxWidth: 700,
                        maxHeight: 320,
                        child: Text(
                          List.filled(48, '🪳').join(' '),
                          style: const TextStyle(
                            fontSize: 26,
                            height: 2.3,
                            letterSpacing: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 14,
            child: Row(
              children: const [
                IconBtn(Icons.ios_share_rounded,
                    iconSize: 16,
                    background: Color(0x80000000)),
                SizedBox(width: 6),
                IconBtn(Icons.settings_outlined,
                    iconSize: 16,
                    background: Color(0x80000000)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single post-grid tile.
class _GridCell extends StatelessWidget {
  final String emoji;
  final int variant;
  final bool pinned;
  const _GridCell({
    required this.emoji,
    required this.variant,
    required this.pinned,
  });

  @override
  Widget build(BuildContext context) {
    final Gradient bg = switch (variant) {
      0 => RadialGradient(
          center: const Alignment(-0.4, -0.2),
          radius: 1.0,
          colors: [
            CG.accent2.withValues(alpha: 0.3),
            const Color(0xFF1A0F00),
          ],
        ),
      1 => RadialGradient(
          center: const Alignment(0.4, 0.2),
          radius: 1.0,
          colors: [
            CG.danger.withValues(alpha: 0.18),
            const Color(0xFF231500),
          ],
        ),
      _ => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF231500), Color(0xFF1A0F00)],
        ),
    };
    return Container(
      decoration: BoxDecoration(
        gradient: bg,
        border: Border.all(color: CG.line),
      ),
      child: Stack(
        children: [
          Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          if (pinned)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x8C000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('📌 PIN',
                    style: T.heading(9,
                        weight: FontWeight.w700, color: CG.accent2)),
              ),
            ),
        ],
      ),
    );
  }
}
