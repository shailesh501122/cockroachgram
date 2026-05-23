import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gradient_text.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'signup_screen.dart';

/// Screen 01 — splash / landing.
///
/// Also acts as the auth gate: while [AuthState] is bootstrapping it shows the
/// brand mark with no CTAs; once finished, signed-in users are forwarded to
/// [MainShell] automatically, otherwise the Join / Log-in buttons appear.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _join() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
      );

  void _login() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

  void _goToShellIfSignedIn(AuthState auth) {
    if (_navigated || !auth.bootstrapped || !auth.isSignedIn || !mounted) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    _goToShellIfSignedIn(auth);

    return Scaffold(
      backgroundColor: CG.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.1,
            colors: [Color(0xFF2A1700), CG.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: -6 * math.pi / 180,
                        child: Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: CG.accentGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: CG.accentGlow,
                                blurRadius: 60,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: const Text('🪳', style: TextStyle(fontSize: 52)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Cockroach',
                                style: T.display(56, spacingEm: 0.03)),
                            GradientText('Gram',
                                style: T.display(56, spacingEm: 0.03)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"Your political voice. Unsilenced."',
                        style: T.body(15,
                            color: CG.text2, style: FontStyle.italic),
                      ),
                      const SizedBox(height: 32),
                      if (!auth.bootstrapped)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: CG.accent2,
                          ),
                        )
                      else ...[
                        CGButton('Join the Movement', onTap: _join),
                        const SizedBox(height: 12),
                        CGButton('Log in', primary: false, onTap: _login),
                      ],
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          style: T.heading(11,
                              weight: FontWeight.w700,
                              color: CG.text3,
                              spacingEm: 0.05),
                          children: const [
                            TextSpan(text: 'COCKROACH MEMBER #00'),
                            TextSpan(
                                text: '42,871',
                                style: TextStyle(color: CG.accent2)),
                            TextSpan(text: ' · INDIA'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'By continuing you agree to the Cockroach Manifesto · Terms · Privacy',
                  textAlign: TextAlign.center,
                  style: T.body(11, color: CG.text3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
