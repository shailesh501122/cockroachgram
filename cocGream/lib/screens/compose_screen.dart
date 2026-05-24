import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/auth_state.dart';
import '../api/repositories.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Screen 04 — compose a new "Roar" (post). Returns the new [Post] on submit.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  static const _max = 280;
  static const _audiences = ['Public', 'State only', 'Followers'];
  static const _audienceKeys = ['public', 'state', 'followers'];

  final _controller = TextEditingController();
  int _audience = 0;
  final Set<String> _tags = {};
  bool _busy = false;
  String? _error;

  /// Topic chips — pulled live from the trending API.
  List<String> _topicTags = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _loadTopicTags();
  }

  Future<void> _loadTopicTags() async {
    try {
      final trends = await TrendingRepository.instance.list(window: 'week');
      if (!mounted) return;
      setState(() {
        _topicTags = trends
            .map((t) => t.tag.replaceFirst('#', ''))
            .take(12)
            .toList();
      });
    } catch (_) {
      // Best-effort — chips just stay empty if the API isn't reachable.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPost {
    if (_busy) return false;
    final t = _controller.text.trim();
    return t.isNotEmpty && _controller.text.length <= _max;
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final post = await PostsRepository.instance.create(
        text: _controller.text,
        tags: _tags.toList(),
        audience: _audienceKeys[_audience],
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final len = _controller.text.length;
    final ratio = len / _max;
    final counterColor = ratio > 1
        ? CG.danger
        : ratio > 0.85
            ? CG.accent2
            : CG.text3;

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Modal head =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Text('Cancel',
                          style: T.heading(13,
                              weight: FontWeight.w700, color: CG.text2)),
                    ),
                  ),
                  Expanded(
                    child: Text('New Roar',
                        textAlign: TextAlign.center, style: T.heading(16)),
                  ),
                  GestureDetector(
                    onTap: _canPost ? _submit : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _canPost ? CG.accent2 : CG.bg3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_busy ? 'Posting…' : 'Post',
                          style: T.body(13,
                              weight: FontWeight.w600,
                              color: _canPost ? CG.bg : CG.text3)),
                    ),
                  ),
                ],
              ),
            ),
            // ===== Compose area =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(
                          context.watch<AuthState>().currentUser?.initials ?? '?',
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.watch<AuthState>().currentUser?.name
                                  ?? 'You',
                              style: T.body(14, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => setState(() =>
                                  _audience = (_audience + 1) % 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_audiences[_audience],
                                      style: T.body(12,
                                          weight: FontWeight.w500,
                                          color: CG.accent2)),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 14, color: CG.accent2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: CG.accent2,
                        style: T.body(18, height: 1.45),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: "What's your political opinion?",
                          hintStyle: T.body(18, color: CG.text3, height: 1.45),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_topicTags.isNotEmpty) ...[
                      Text('TRENDING THIS WEEK', style: T.labelSm()),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in _topicTags)
                            _TagChip(
                              label: '#$t',
                              active: _tags.contains(t),
                              onTap: () => setState(() {
                                _tags.contains(t)
                                    ? _tags.remove(t)
                                    : _tags.add(t);
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(_error!,
                    style: T.body(12,
                        color: CG.danger, weight: FontWeight.w600)),
              ),
            // ===== Toolbar =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CG.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _toolBtn(Icons.image_outlined),
                      const SizedBox(width: 4),
                      _toolBtn(Icons.gif_box_outlined),
                      const SizedBox(width: 4),
                      _toolBtn(Icons.bar_chart_rounded),
                      const SizedBox(width: 4),
                      _toolBtn(Icons.location_on_outlined),
                    ],
                  ),
                  Text(
                    '$len/$_max',
                    style: T.body(12,
                        weight: FontWeight.w600, color: counterColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon) => IconBtn(
        icon,
        size: 36,
        iconColor: CG.accent2,
      );
}

/// Selectable topic chip.
class _TagChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TagChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? CG.accent2 : Colors.transparent,
          border: Border.all(color: active ? CG.accent2 : CG.line2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: T.body(12,
              weight: FontWeight.w500, color: active ? CG.bg : CG.text2),
        ),
      ),
    );
  }
}
