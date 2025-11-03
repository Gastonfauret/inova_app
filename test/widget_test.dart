import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inova_app/main.dart';

void main() {
  testWidgets('Enrollment screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // isEnrolled: false should show the EnrollmentScreen.
    await tester.pumpWidget(const MyApp(isEnrolled: false));

    // Verify the title and instructional text are displayed.
    expect(find.text('Enrolamiento de Dispositivo'), findsOneWidget);
    expect(find.text('Por favor, ingrese su código de enlace para continuar.'), findsOneWidget);

    // Verify the single text form field and its properties are correct.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Código de Enlace'), findsOneWidget);
    expect(find.byIcon(Icons.vpn_key), findsOneWidget);

    // Verify the button is displayed.
    expect(find.widgetWithText(ElevatedButton, 'Enlazar Dispositivo'), findsOneWidget);
  });
}
