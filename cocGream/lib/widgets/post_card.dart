import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import 'common.dart';

/// Splits post text into spans, rendering #hashtags in amber.
List<TextSpan> hashtagSpans(String text) {
  final spans = <TextSpan>[];
  final re = RegExp(r'(#\w+)');
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
    spans.add(TextSpan(
      text: m.group(0),
      style: const TextStyle(color: CG.accent2, fontWeight: FontWeight.w500),
    ));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// Instagram-style feed post.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onRepost;
  const PostCard({super.key, required this.post, this.onLike, this.onRepost});

  @override
  Widget build(BuildContext context) {
    final hasLikes = post.likes > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CG.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 12, 10),
            child: Row(
              children: [
                Avatar(post.initials, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.name,
                              overflow: TextOverflow.ellipsis,
                              style: T.body(13.5, weight: FontWeight.w600),
                            ),
                          ),
                          if (post.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 14, color: CG.accent2),
                          ],
                        ],
                      ),
                      if (post.location.isNotEmpty)
                        Text(post.location,
                            style: T.body(11, color: CG.text3, height: 1.3)),
                    ],
                  ),
                ),
                Text(post.time,
                    style: T.body(12, color: CG.text3)),
                const SizedBox(width: 8),
                const Icon(Icons.more_horiz, size: 20, color: CG.text2),
              ],
            ),
          ),
          // ===== Media =====
          if (post.media != null) _PostMediaCard(caption: post.media!.caption),
          // ===== Actions =====
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                _iconAction(
                  post.liked ? Icons.favorite : Icons.favorite_border,
                  color: post.liked ? CG.danger : CG.text,
                  onTap: onLike,
                ),
                _iconAction(Icons.mode_comment_outlined),
                _iconAction(
                  Icons.repeat_rounded,
                  color: post.reposted ? CG.success : CG.text,
                  onTap: onRepost,
                ),
                _iconAction(Icons.send_outlined),
                const Spacer(),
                _iconAction(Icons.bookmark_border),
              ],
            ),
          ),
          // ===== Likes count =====
          if (hasLikes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                '${fmt(post.likes)} ${post.likes == 1 ? "like" : "likes"}',
                style: T.body(13, weight: FontWeight.w600),
              ),
            ),
          // ===== Caption (username + text) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Text.rich(
              TextSpan(
                style: T.body(13.5, height: 1.4),
                children: [
                  TextSpan(
                    text: '${post.author.username}  ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...hashtagSpans(post.text),
                ],
              ),
            ),
          ),
          // ===== View comments hint =====
          if (post.comments > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              child: Text(
                'View all ${fmt(post.comments)} comments',
                style: T.body(13, color: CG.text3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, {Color color = CG.text, VoidCallback? onTap}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(icon, size: 24, color: color),
        ),
      );
}

/// Media placeholder — keeps the visual feel without the heavy amber wash.
class _PostMediaCard extends StatelessWidget {
  final String caption;
  const _PostMediaCard({required this.caption});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // square — Instagram default
      child: Container(
        decoration: const BoxDecoration(
          color: CG.bg2,
          border: Border(
            top: BorderSide(color: CG.line),
            bottom: BorderSide(color: CG.line),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.2),
                    radius: 0.9,
                    colors: [
                      CG.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: T.body(13,
                      color: CG.text2, weight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
