import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/auth_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';

/// Screen 03 — home feed: stories (derived from posts), tabs and post cards.
class FeedScreen extends StatelessWidget {
  final List<Post> posts;
  final bool loading;
  final String? error;
  final String feedTab;
  final ValueChanged<String> onFeedTab;
  final void Function(Post) onLike;
  final void Function(Post) onRepost;
  final Future<void> Function() onRefresh;
  final VoidCallback onBell;

  const FeedScreen({
    super.key,
    required this.posts,
    required this.loading,
    required this.error,
    required this.feedTab,
    required this.onFeedTab,
    required this.onLike,
    required this.onRepost,
    required this.onRefresh,
    required this.onBell,
  });

  static const _tabKeys = ['foryou', 'following', 'state', 'trending'];
  static const _tabLabels = ['For You', 'Following', 'State', 'Trending'];

  /// Unique authors from the current feed — these become the stories row.
  List<User> _authorsFromFeed() {
    final seen = <int>{};
    final out = <User>[];
    for (final p in posts) {
      if (seen.add(p.author.id)) out.add(p.author);
      if (out.length >= 12) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthState>().currentUser;
    final storyAuthors = _authorsFromFeed();
    return Column(
      children: [
        AppHeader(onBell: onBell),
        Expanded(
          child: RefreshIndicator(
            color: CG.accent2,
            backgroundColor: CG.bg2,
            onRefresh: onRefresh,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ===== Stories =====
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: CG.line)),
                  ),
                  child: SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (me != null)
                          _StoryItem(
                            label: 'Your story',
                            initials: me.initials,
                            isMe: true,
                          ),
                        for (final u in storyAuthors)
                          if (me == null || u.id != me.id)
                            _StoryItem(
                              label: u.name.split(' ').first,
                              initials: u.initials,
                            ),
                      ],
                    ),
                  ),
                ),
                // ===== Tabs =====
                CGTabs(
                  labels: _tabLabels,
                  selected: _tabKeys.indexOf(feedTab),
                  onChanged: (i) => onFeedTab(_tabKeys[i]),
                ),
                // ===== Body =====
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: CG.accent2),
                    ),
                  )
                else if (error != null)
                  _FeedError(message: error!, onRetry: onRefresh)
                else if (posts.isEmpty)
                  const FeedCaption(
                    'No roars here yet. Be the first.',
                    padding: EdgeInsets.fromLTRB(20, 60, 20, 120),
                  )
                else ...[
                  for (final p in posts)
                    PostCard(
                      post: p,
                      onLike: () => onLike(p),
                      onRepost: () => onRepost(p),
                    ),
                  const FeedCaption(
                    "You're all caught up.",
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

class _FeedError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _FeedError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 30, color: CG.text3),
            const SizedBox(height: 12),
            Text("Couldn't load the feed.",
                style: T.body(14, color: CG.text2, weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: T.body(12, color: CG.text3)),
            const SizedBox(height: 18),
            CGButton('Retry', primary: false, onTap: () => onRetry()),
          ],
        ),
      ),
    );
  }
}

/// Instagram-style story bubble. Amber ring for everyone except "Your story".
class _StoryItem extends StatelessWidget {
  final String label;
  final String initials;
  final bool isMe;
  const _StoryItem({
    required this.label,
    required this.initials,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMe ? CG.line2 : CG.accent2,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CG.bg2,
                      border: Border.all(color: CG.bg, width: 2),
                    ),
                    child: Text(
                      initials,
                      style: T.body(15,
                          weight: FontWeight.w600, height: 1),
                    ),
                  ),
                ),
                if (isMe)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CG.accent2,
                        border: Border.all(color: CG.bg, width: 2),
                      ),
                      child: const Icon(Icons.add,
                          size: 12, color: CG.bg),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.body(11, color: CG.text2, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
