import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inova_app/main.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login screen is displayed
    expect(find.text('Inova MDM'), findsOneWidget);
    expect(find.text('Gestión de Dispositivos Móviles'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Login screen has required fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify form fields exist
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });
}
