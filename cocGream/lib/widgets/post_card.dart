import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import 'common.dart';

/// Splits post text into spans, rendering #hashtags in amber.
List<TextSpan> hashtagSpans(String text, {Color base = CG.text}) {
  final spans = <TextSpan>[];
  final re = RegExp(r'(#\w+)');
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: const TextStyle(color: CG.accent2, fontWeight: FontWeight.w600),
    ));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// A single feed post card.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onRepost;
  const PostCard({super.key, required this.post, this.onLike, this.onRepost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CG.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Head =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(post.initials, size: 42),
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
                            style: T.body(14, weight: FontWeight.w700),
                          ),
                        ),
                        if (post.verified) ...[
                          const SizedBox(width: 4),
                          const Text('✓',
                              style: TextStyle(color: CG.accent2, fontSize: 14)),
                        ],
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            post.handle,
                            overflow: TextOverflow.ellipsis,
                            style: T.body(13, weight: FontWeight.w500, color: CG.text3),
                          ),
                        ),
                        const Spacer(),
                        Text('· ${post.time}',
                            style: T.body(13, color: CG.text3)),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: CG.text3),
                        const SizedBox(width: 3),
                        Text(post.location, style: T.body(12, color: CG.text3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ===== Text =====
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text.rich(
              TextSpan(
                style: T.body(14, height: 1.45),
                children: hashtagSpans(post.text),
              ),
            ),
          ),
          // ===== Media =====
          if (post.media != null) _PostMediaCard(caption: post.media!.caption),
          // ===== Actions =====
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _action(
                  post.liked ? Icons.favorite : Icons.favorite_border,
                  fmt(post.likes),
                  color: post.liked ? CG.danger : CG.text3,
                  onTap: onLike,
                ),
                _action(Icons.mode_comment_outlined, fmt(post.comments)),
                _action(
                  Icons.repeat_rounded,
                  fmt(post.reposts),
                  color: post.reposted ? CG.success : CG.text3,
                  onTap: onRepost,
                ),
                _action(Icons.ios_share_rounded, null),
                _action(Icons.bookmark_border_rounded, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String? count,
      {Color color = CG.text3, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(count, style: T.body(12, weight: FontWeight.w600, color: color)),
          ],
        ],
      ),
    );
  }
}

/// The 16:10 media placeholder card with amber/red radial wash.
class _PostMediaCard extends StatelessWidget {
  final String caption;
  const _PostMediaCard({required this.caption});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CG.rMd),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: CG.line)),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.2),
                      radius: 0.9,
                      colors: [
                        CG.accent2.withValues(alpha: 0.4),
                        const Color(0xFF2D1D05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.4, 0.2),
                      radius: 0.9,
                      colors: [
                        CG.danger.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪳', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: T.body(12, weight: FontWeight.w600, color: CG.text2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
