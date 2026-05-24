import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/auth_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Screen 06 — Instagram-clean member profile.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  /// Posts the parent already has loaded — used to fill the grid without
  /// firing another request. Filtered to those authored by the current user.
  final List<Post> posts;
  const ProfileScreen({
    super.key,
    this.onSignOut,
    this.posts = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: CG.accent2));
    }
    final myPosts =
        widget.posts.where((p) => p.author.id == user.id).toList();

    return Column(
      children: [
        // ===== Header (username + sign-out) =====
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        overflow: TextOverflow.ellipsis,
                        style: T.heading(20, weight: FontWeight.w700),
                      ),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 18, color: CG.accent2),
                    ],
                  ],
                ),
              ),
              if (widget.onSignOut != null)
                GestureDetector(
                  onTap: widget.onSignOut,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.logout_rounded, size: 22, color: CG.text),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ===== Avatar + stats =====
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Row(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CG.accent2,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CG.bg2,
                          border: Border.all(color: CG.bg, width: 2),
                        ),
                        child: Text(
                          user.initials,
                          style: T.heading(28, weight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat(fmt(user.stats.posts), 'Posts'),
                          _stat(fmt(user.stats.followers), 'Followers'),
                          _stat(fmt(user.stats.following), 'Following'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Name + bio =====
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                child: Text(user.name,
                    style: T.body(14, weight: FontWeight.w600)),
              ),
              if (user.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
                  child: Text(user.bio, style: T.body(13, height: 1.4)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (user.memberNo.isNotEmpty)
                      Text(
                        '🪳 Member #${user.memberNo}',
                        style: T.body(11,
                            color: CG.accent2, weight: FontWeight.w500),
                      ),
                    if (user.state.isNotEmpty)
                      Text(user.state, style: T.body(11, color: CG.text3)),
                    Text('· ${fmt(user.stats.roars)} roars',
                        style: T.body(11, color: CG.text3)),
                  ],
                ),
              ),

              // ===== Actions =====
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(
                  children: const [
                    Expanded(child: CGButton('Edit profile', primary: false)),
                    SizedBox(width: 6),
                    Expanded(child: CGButton('Share profile', primary: false)),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // ===== Tab row =====
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CG.line)),
                ),
                child: Row(
                  children: [
                    _profileTab(0, Icons.grid_on_outlined),
                    _profileTab(1, Icons.collections_outlined),
                    _profileTab(2, Icons.bookmark_border),
                  ],
                ),
              ),

              // ===== Grid / empty state =====
              if (myPosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: CG.text, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 28, color: CG.text),
                        ),
                        const SizedBox(height: 14),
                        Text('No roars yet',
                            style: T.heading(18, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          'When you post your first roar, it will appear here.',
                          textAlign: TextAlign.center,
                          style: T.body(13, color: CG.text3),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: myPosts.length,
                  itemBuilder: (_, i) => _GridCell(post: myPosts[i]),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String num, String label) => Column(
        children: [
          Text(num, style: T.heading(18, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: T.body(13, color: CG.text2)),
        ],
      );

  Widget _profileTab(int index, IconData icon) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CG.text : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Icon(icon, size: 22, color: active ? CG.text : CG.text3),
        ),
      ),
    );
  }
}

/// One post tile in the 3-column grid. Text-based since we don't have images yet.
class _GridCell extends StatelessWidget {
  final Post post;
  const _GridCell({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CG.bg2,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.2),
          radius: 0.9,
          colors: [
            CG.accent.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomLeft,
      child: Text(
        post.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: T.body(11, color: CG.text2, height: 1.3),
      ),
    );
  }
}
