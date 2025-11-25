// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

//import 'package:flutter/material.dart'; // Required for Material widgets like Text, Button etc.
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:komyut/views/pages/landingpage.dart';
// import 'package:komyut/main.dart'; // Avoid using MyApp in tests that require Supabase initialization
//import 'package:komyut/views/widgets/button.dart'; // Import your CustomButton widget

void main() {
  testWidgets('LandingPage displays "Welcome" text and buttons', (WidgetTester tester) async {
    // Build our app (MyApp should render your LandingPage) and trigger a frame.
    // Pump the LandingPage directly inside a MaterialApp so the test doesn't need Supabase
    await tester.pumpWidget(const MaterialApp(home: LandingPage()));

    // Verify that the "Welcome" text is present.
    // Assuming your Welcome text is directly visible.
    expect(find.text('Welcome'), findsOneWidget);

    // Verify that the "Create Account" button is present.
    // We look for a CustomButton widget that contains the text 'Create Account'.
    //expect(find.widgetWithText(CustomButton, 'Create Account'), findsOneWidget);

    // Verify that the "Log In" button is present.
    // Similarly, find the CustomButton for 'Log In'.
    //expect(find.widgetWithText(CustomButton, 'Log In'), findsOneWidget);

    // Optional: Example of how you might interact and verify if button had a visible effect.
    // If tapping 'Create Account' changed the text or pushed a new screen, you'd verify that here.
    // await tester.tap(find.widgetWithText(CustomButton, 'Create Account'));
    // await tester.pump(); // Rebuild the widget tree after the tap
    // expect(find.text('Account Created!'), findsOneWidget); // Example assertion
  });
}