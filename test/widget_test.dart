import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/main.dart';  // Ensure this import is correct
import 'package:flutter/material.dart';

void main() {
  testWidgets('SummitTrack loads HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SummitTrackApp());  // This should work if SummitTrackApp is defined

    // Check if the HomeScreen has these widgets
    expect(find.text('Mountain List'), findsOneWidget);
    expect(find.text('Start Hiking'), findsOneWidget);
    expect(find.text('My Reflections'), findsOneWidget);
  });
}
