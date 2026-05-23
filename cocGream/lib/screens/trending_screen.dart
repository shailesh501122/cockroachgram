import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/repositories.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Screen 05 — ranked trending hashtags. Pulls from `/api/trending/`.
class TrendingScreen extends StatefulWidget {
  final VoidCallback onBell;
  const TrendingScreen({super.key, required this.onBell});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  static const _tabKeys = ['now', 'today', 'week', 'state'];
  static const _tabLabels = ['Now', 'Today', 'Week', 'State'];

  int _tab = 0;
  List<Trend> _trends = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = _trends.isEmpty;
      _error = null;
    });
    try {
      final t = await TrendingRepository.instance.list(window: _tabKeys[_tab]);
      if (!mounted) return;
      setState(() {
        _trends = t;
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

  void _setTab(int i) {
    if (_tab == i) return;
    setState(() {
      _tab = i;
      _trends = const [];
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(onBell: widget.onBell),
        PageHead(
          title: 'Trending Now',
          sub: 'Updated 2 minutes ago · India',
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
                else if (_trends.isEmpty)
                  const FeedCaption(
                    '🪳 The streets are quiet — for now.',
                    padding: EdgeInsets.all(40),
                  )
                else ...[
                  for (final t in _trends) _TrendRow(trend: t),
                  const FeedCaption(
                    '🪳 The streets are loud today.',
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

class _TrendRow extends StatelessWidget {
  final Trend trend;
  const _TrendRow({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isTop = trend.rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CG.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              trend.rank.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: T.display(32, color: isTop ? CG.accent2 : CG.text3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        trend.tag,
                        overflow: TextOverflow.ellipsis,
                        style: T.heading(17),
                      ),
                    ),
                    if (trend.hot)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('🔥', style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${trend.category}  ·  ${trend.count}',
                  style: T.body(12, color: CG.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const IconBtn(Icons.chevron_right, size: 32, iconSize: 14),
        ],
      ),
    );
  }
}
