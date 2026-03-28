import 'package:flutter_test/flutter_test.dart';
import 'package:qrostlina/main.dart';

void main() {
  testWidgets('Main menu smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QRostlinaApp());

    // Verify that the title is present.
    expect(find.text('QROSTLINA'), findsOneWidget);
    
    // Verify menu items
    expect(find.text('SCAN QR CODE'), findsOneWidget);
    expect(find.text('SPECIES LIST'), findsOneWidget);
    expect(find.text('LOCATIONS'), findsOneWidget);
  });
}
