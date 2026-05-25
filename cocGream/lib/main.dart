import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'api/auth_state.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,   // dark icons on light bar
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: CG.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: CG.line,
    ),
  );
  runApp(const CockroachGramApp());
}

/// CockroachGram — "Your political voice. Unsilenced."
class CockroachGramApp extends StatelessWidget {
  const CockroachGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return ChangeNotifierProvider(
      create: (_) => AuthState()..bootstrap(),
      child: MaterialApp(
        title: 'CockroachGram',
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          scaffoldBackgroundColor: CG.bg,
          colorScheme: base.colorScheme.copyWith(
            brightness: Brightness.light,
            primary: CG.accent2,
            secondary: CG.accent,
            surface: CG.bg,
            onSurface: CG.text,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
              .apply(bodyColor: CG.text, displayColor: CG.text),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: CG.accent2,
            selectionColor: CG.accentSoft,
            selectionHandleColor: CG.accent2,
          ),
          splashColor: CG.accent2.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
