import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zomia_frontend/app/zomia_app.dart';

void main() {
  testWidgets('renders the Zomia app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZomiaApp()));

    expect(find.text('Zomia'), findsOneWidget);
    expect(find.text('Staff Service'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
