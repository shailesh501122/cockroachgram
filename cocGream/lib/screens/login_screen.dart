import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Log-in screen — username/email/phone + password against `/api/auth/login/`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_identifier, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_identifier, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy && _identifier.text.trim().isNotEmpty && _password.text.length >= 6;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().signin(
            identifier: _identifier.text.trim(),
            password: _password.text,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left,
                            size: 22, color: CG.text2),
                      ),
                    ),
                    Expanded(
                      child: Text('Welcome back',
                          textAlign: TextAlign.center, style: T.heading(16)),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Transform.rotate(
                  angle: -6 * math.pi / 180,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: CG.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CG.glow(blur: 28, y: 14),
                    ),
                    child: const Text('🪳', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('Log in', style: T.display(34))),
              const SizedBox(height: 4),
              Center(
                child: Text('The streets are waiting.',
                    style: T.body(13, color: CG.text3)),
              ),
              const SizedBox(height: 28),
              Text('USERNAME, EMAIL OR PHONE', style: T.labelSm()),
              const SizedBox(height: 6),
              _AuthField(
                icon: Icons.alternate_email,
                controller: _identifier,
                hint: 'aaravm  or  you@cjp.in',
              ),
              const SizedBox(height: 14),
              Text('PASSWORD', style: T.labelSm()),
              const SizedBox(height: 6),
              _AuthField(
                icon: Icons.lock_outline,
                controller: _password,
                hint: 'Min 6 characters',
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: T.body(12, color: CG.danger, weight: FontWeight.w600)),
              ],
              const SizedBox(height: 22),
              CGButton(
                _busy ? 'Logging in…' : 'Log in',
                enabled: _canSubmit,
                onTap: _submit,
              ),
              const Spacer(),
              Text(
                'By logging in you re-affirm the Cockroach Manifesto.',
                textAlign: TextAlign.center,
                style: T.body(11, color: CG.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal copy of the signup field — kept local to avoid a circular import.
class _AuthField extends StatefulWidget {
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  const _AuthField({
    required this.icon,
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
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
