import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/auth_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Screen 02 — three-step sign-up flow with live validation + progress dots.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _step = 0;
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  String _state = '';
  bool _agree = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _username, _contact, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _contact, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _name.text.isNotEmpty && _username.text.isNotEmpty;
      case 1:
        return _contact.text.isNotEmpty && _password.text.length >= 6;
      default:
        return _state.isNotEmpty && _agree;
    }
  }

  Future<void> _next() async {
    if (!_stepValid || _busy) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().signup(
            name: _name.text.trim(),
            username: _username.text.trim(),
            contact: _contact.text.trim(),
            password: _password.text,
            state: _state,
            agree: _agree,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  static const _titles = ['Who are you?', 'Lock it down', 'Where do you stand?'];
  static const _subs = [
    'Your name, your handle. Make it loud.',
    "We don't sell data. We organize people.",
    'Pick your state and sign the manifesto.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== Modal head =====
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _back,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left, size: 22, color: CG.text2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Join CockroachGram',
                        textAlign: TextAlign.center,
                        style: T.heading(16),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // ===== Step header =====
              Column(
                children: [
                  Transform.rotate(
                    angle: -6 * math.pi / 180,
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: CG.accentGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: CG.glow(blur: 24, y: 12),
                      ),
                      child: const Text('🪳', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(_titles[_step], style: T.display(32)),
                  const SizedBox(height: 4),
                  Text(_subs[_step],
                      textAlign: TextAlign.center,
                      style: T.body(13, color: CG.text3)),
                ],
              ),
              const SizedBox(height: 22),
              // ===== Step body =====
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _stepBody(),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: T.body(12, color: CG.danger, weight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              CGButton(
                _busy
                    ? 'Signing manifesto…'
                    : (_step == 2 ? 'Sign Manifesto · Join' : 'Continue'),
                enabled: _stepValid && !_busy,
                onTap: _next,
              ),
              const SizedBox(height: 16),
              // ===== Progress dots =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _step ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: i == _step
                            ? const LinearGradient(
                                colors: [CG.accent, CG.accent2])
                            : null,
                        color: i == _step ? null : CG.line2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return Column(
          key: const ValueKey(0),
          children: [
            _Field(
              label: 'Full Name',
              child: _CGInput(
                icon: Icons.person_outline,
                controller: _name,
                hint: 'Aarav Mehta',
              ),
            ),
            _Field(
              label: 'Username',
              child: _CGInput(
                icon: Icons.alternate_email,
                controller: _username,
                hint: 'aaravm',
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Email or Phone',
              child: _CGInput(
                icon: Icons.mail_outline,
                controller: _contact,
                hint: 'you@cjp.in or +91…',
              ),
            ),
            _Field(
              label: 'Password',
              child: _CGInput(
                icon: Icons.lock_outline,
                controller: _password,
                hint: 'Min 6 characters',
                obscure: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text.rich(
                TextSpan(
                  style: T.body(11, color: CG.text3, height: 1.5),
                  children: const [
                    TextSpan(text: 'Use a passphrase. '),
                    TextSpan(
                        text: '"YeMeraDeshHai2026"',
                        style: TextStyle(color: CG.accent2)),
                    TextSpan(text: ' beats '),
                    TextSpan(
                        text: 'p@ssw0rd',
                        style: TextStyle(color: CG.text2)),
                    TextSpan(text: ' every time.'),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Your State',
              child: _StateDropdown(
                value: _state,
                onChanged: (v) => setState(() => _state = v ?? ''),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _agree = !_agree),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: CG.bg2,
                  border: Border.all(color: CG.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: _agree ? CG.accentGradient : null,
                        border: _agree
                            ? null
                            : Border.all(color: CG.line2, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _agree
                          ? const Icon(Icons.check, size: 14, color: CG.bg)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: T.body(13, color: CG.text2, height: 1.4),
                          children: const [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                                text: 'Cockroach Manifesto',
                                style: TextStyle(
                                    color: CG.text,
                                    fontWeight: FontWeight.w700)),
                            TextSpan(
                                text:
                                    ' — to organize peacefully, vote informed, and call out corruption regardless of party. '),
                            TextSpan(
                                text: 'v2.0',
                                style: TextStyle(color: CG.text3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CG.accent2.withValues(alpha: 0.06),
                border: Border.all(color: CG.accent2.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text.rich(
                TextSpan(
                  style: T.body(12, color: CG.text2, height: 1.5),
                  children: const [
                    TextSpan(
                      text: '🪳 Manifesto preview: ',
                      style: TextStyle(
                          color: CG.accent2, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                        text:
                            '"We are not pests. We are the people who survived every regime. We organize. We vote. We remember."'),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

/// Uppercase label + field slot.
class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: T.labelSm()),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// The `.input-wrap` text field — icon + input with an amber focus glow.
class _CGInput extends StatefulWidget {
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;
  const _CGInput({
    required this.icon,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.inputFormatters,
  });

  @override
  State<_CGInput> createState() => _CGInputState();
}

class _CGInputState extends State<_CGInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CG.bg2,
        border: Border.all(color: focused ? CG.accent : CG.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: CG.accent2.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 3,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: CG.text3),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              inputFormatters: widget.inputFormatters,
              cursorColor: CG.accent2,
              style: T.body(14, height: 1.2),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: T.body(14, color: CG.text3, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// State picker styled as an `.input-wrap`.
class _StateDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _StateDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: CG.bg2,
        border: Border.all(color: CG.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18, color: CG.text3),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.isEmpty ? null : value,
                isExpanded: true,
                isDense: true,
                dropdownColor: CG.bg2,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.chevron_right, color: CG.text3),
                hint: Text('Select your state…',
                    style: T.body(14, color: CG.text3)),
                style: T.body(14),
                items: [
                  for (final s in kStates)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
