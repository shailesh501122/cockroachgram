// Basic smoke test for CockroachGram.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cockroachgram/main.dart';

void main() {
  testWidgets('Splash renders the brand mark', (tester) async {
    await tester.pumpWidget(const CockroachGramApp());
    // Single frame is enough to render the splash; the CTAs are gated on
    // an async auth bootstrap which we don't pump here.
    await tester.pump();

    expect(find.text('Cockroach'), findsOneWidget);
    expect(find.text('Gram'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
