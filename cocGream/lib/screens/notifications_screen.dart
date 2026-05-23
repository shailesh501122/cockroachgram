import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/repositories.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Screen 07 — activity / alerts feed. Pulls from `/api/notifications/`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _tabKeys = ['all', 'mentions', 'likes', 'follows'];
  static const _tabLabels = ['All', 'Mentions', 'Likes', 'Follows'];

  int _tab = 0;
  List<Notif> _items = const [];
  bool _loading = true;
  String? _error;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final items =
          await NotificationsRepository.instance.list(filter: _tabKeys[_tab]);
      if (!mounted) return;
      final unread = items.where((n) => n.unread).length;
      setState(() {
        _items = items;
        _unread = unread;
        _loading = false;
      });
      // Best-effort mark-all-read after rendering.
      if (unread > 0) {
        NotificationsRepository.instance.markAllRead().catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeError(e);
      });
    }
  }

  void _setTab(int i) {
    if (_tab == i) return;
    setState(() {
      _tab = i;
      _items = const [];
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(unread: false),
        PageHead(
          title: 'Alerts',
          sub: _unread > 0
              ? '$_unread new since you were last on the streets'
              : "You're caught up",
          trailing: const IconBtn(Icons.settings_outlined),
        ),
        CGTabs(
          labels: _tabLabels,
          selected: _tab,
          onChanged: _setTab,
        ),
        Expanded(
          child: RefreshIndicator(
            color: CG.accent2,
            backgroundColor: CG.bg2,
            onRefresh: _fetch,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: CG.accent2),
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: T.body(12, color: CG.text3)),
                    ),
                  )
                else if (_items.isEmpty)
                  const FeedCaption(
                    '🪳 No new noise.',
                    padding: EdgeInsets.all(40),
                  )
                else ...[
                  for (final n in _items) _NotifRow(notif: n),
                  const FeedCaption(
                    "🪳 You've reached the bottom of the noise.",
                    padding: EdgeInsets.all(28),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  final Notif notif;
  const _NotifRow({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: notif.unread ? CG.accent2.withValues(alpha: 0.04) : null,
        border: const Border(bottom: BorderSide(color: CG.line)),
      ),
      child: Stack(
        children: [
          if (notif.unread)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CG.accent2,
                    boxShadow: CG.glow(blur: 6, y: 0),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Avatar(notif.initials, size: 42),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: _NotifBadge(type: notif.type),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: T.body(14, height: 1.4),
                          children: [
                            TextSpan(
                              text: notif.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            if (notif.verified)
                              const TextSpan(
                                text: ' ✓',
                                style: TextStyle(color: CG.accent2),
                              ),
                            TextSpan(
                              text: ' ${notif.text}',
                              style: const TextStyle(color: CG.text2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${notif.time} ago',
                          style: T.body(12, color: CG.text3)),
                      if (notif.preview != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: CG.bg2,
                            border: Border.all(color: CG.line),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('"${notif.preview}"',
                              style: T.body(12, color: CG.text2, height: 1.4)),
                        ),
                    ],
                  ),
                ),
                if (notif.type == NotifType.follow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CG.bg3,
                      border: Border.all(color: CG.line2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Follow',
                        style: T.heading(11, weight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The small type-coded badge overlaid on the notification avatar.
class _NotifBadge extends StatelessWidget {
  final NotifType type;
  const _NotifBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (type) {
      NotifType.like => (Icons.favorite, CG.danger, Colors.white),
      NotifType.comment => (Icons.mode_comment, CG.info, Colors.white),
      NotifType.follow => (Icons.person_add_alt_1, CG.success, Colors.white),
      NotifType.repost => (Icons.repeat_rounded, CG.accent2, CG.bg),
      NotifType.mention => (Icons.alternate_email, CG.info, Colors.white),
    };
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: CG.bg, width: 2),
      ),
      child: Icon(icon, size: 11, color: fg),
    );
  }
}
