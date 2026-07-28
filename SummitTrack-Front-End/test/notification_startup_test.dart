import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/main.dart' as app;

void main() {
  testWidgets(
    'an unresolved notification initialization does not block the first frame',
    (tester) async {
      final initialization = Completer<void>();

      runApp(
        const MaterialApp(home: Scaffold(body: Text('SummitTrack normal UI'))),
      );
      app.initializeNotificationsAfterFirstFrame(
        initialize: () => initialization.future,
      );

      await tester.pump();

      expect(find.text('SummitTrack normal UI'), findsOneWidget);
      expect(initialization.isCompleted, isFalse);

      initialization.complete();
      await tester.pump();
    },
  );

  testWidgets(
    'a notification initialization failure is contained after the first frame',
    (tester) async {
      runApp(
        const MaterialApp(home: Scaffold(body: Text('SummitTrack normal UI'))),
      );
      app.initializeNotificationsAfterFirstFrame(
        initialize: () => Future<void>.error(
          StateError('simulated notification permission failure'),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('SummitTrack normal UI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
