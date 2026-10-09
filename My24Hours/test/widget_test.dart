import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my24hours/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('DayTrack 24 smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DayTrackApp());
    await tester.pump(const Duration(seconds: 2));

    // Verify app builds successfully.
    expect(find.byType(DayTrackApp), findsOneWidget);
  });
}
