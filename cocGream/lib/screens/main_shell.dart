import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/auth_state.dart';
import '../api/repositories.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'compose_screen.dart';
import 'feed_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'splash_screen.dart';
import 'trending_screen.dart';

/// The signed-in app shell — feeds, bottom nav, and post-state mutations.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  String _feedTab = 'foryou';
  List<Post> _posts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshFeed();
  }

  int get _slot => _tab >= 3 ? _tab - 1 : _tab;

  void _onNav(int index) {
    if (index == 2) return; // compose handled separately
    setState(() => _tab = index);
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _loading = _posts.isEmpty;
      _error = null;
    });
    try {
      final posts = await PostsRepository.instance.feed(tab: _feedTab);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeError(e);
      });
    }
  }

  void _setFeedTab(String tab) {
    if (tab == _feedTab) return;
    setState(() {
      _feedTab = tab;
      _posts = const [];
    });
    _refreshFeed();
  }

  Future<void> _like(Post p) async {
    final wasLiked = p.liked;
    setState(() {
      p.liked = !wasLiked;
      p.likes += p.liked ? 1 : -1;
    });
    try {
      await PostsRepository.instance.like(p.id, liked: p.liked);
    } catch (_) {
      setState(() {
        p.liked = wasLiked;
        p.likes += p.liked ? 1 : -1;
      });
    }
  }

  Future<void> _repost(Post p) async {
    final wasReposted = p.reposted;
    setState(() {
      p.reposted = !wasReposted;
      p.reposts += p.reposted ? 1 : -1;
    });
    try {
      await PostsRepository.instance.repost(p.id, reposted: p.reposted);
    } catch (_) {
      setState(() {
        p.reposted = wasReposted;
        p.reposts += p.reposted ? 1 : -1;
      });
    }
  }

  Future<void> _openCompose() async {
    final post = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (_) => const ComposeScreen(),
        fullscreenDialog: true,
      ),
    );
    if (post != null) {
      setState(() {
        _posts = [post, ..._posts];
        _tab = 0;
      });
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthState>().signout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      FeedScreen(
        posts: _posts,
        loading: _loading,
        error: _error,
        feedTab: _feedTab,
        onFeedTab: _setFeedTab,
        onLike: _like,
        onRepost: _repost,
        onRefresh: _refreshFeed,
        onBell: () => _onNav(3),
      ),
      TrendingScreen(onBell: () => _onNav(3)),
      const NotificationsScreen(),
      ProfileScreen(onSignOut: _signOut),
    ];

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_slot),
                      child: screens[_slot],
                    ),
                  ),
                  if (_tab == 0)
                    Positioned(
                      bottom: 18,
                      right: 18,
                      child: GestureDetector(
                        onTap: _openCompose,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: CG.accentGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: CG.glow(blur: 32, y: 12),
                          ),
                          child: const Icon(Icons.add, size: 26, color: CG.bg),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            CGBottomNav(
              active: _tab,
              onNav: _onNav,
              onCompose: _openCompose,
            ),
          ],
        ),
      ),
    );
  }
}
