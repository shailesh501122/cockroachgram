import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';

/// Screen 03 — the home feed: stories, tabs and post cards.
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

  @override
  Widget build(BuildContext context) {
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kStories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => _StoryItem(story: kStories[i]),
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
                    "🪳 No roars here yet. Be the first.",
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
                    "🪳 You're caught up. The cockroaches don't sleep.",
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
            const Text('🪳', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('Could not load the feed.',
                style: T.body(13, color: CG.text2, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: T.body(12, color: CG.text3)),
            const SizedBox(height: 16),
            CGButton('Retry', primary: false, onTap: () => onRetry()),
          ],
        ),
      ),
    );
  }
}

/// A single story bubble with the conic amber ring.
class _StoryItem extends StatelessWidget {
  final Story story;
  const _StoryItem({required this.story});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: story.first ? CG.line : null,
              gradient: story.first
                  ? null
                  : const SweepGradient(
                      colors: [
                        CG.accent,
                        CG.accent2,
                        CG.danger,
                        CG.accent,
                      ],
                      transform: GradientRotation(math.pi),
                    ),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CG.bg2,
                border: Border.all(color: CG.bg, width: 2),
              ),
              child: story.first
                  ? const Icon(Icons.add, size: 20, color: CG.accent2)
                  : Text(
                      story.initials ?? '',
                      style: T.heading(18, weight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            story.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.body(11, color: CG.text2),
          ),
        ],
      ),
    );
  }
}
