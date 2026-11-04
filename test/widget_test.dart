import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_finance/app/app.dart';
import 'package:my_finance/app/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MyFinanceApp smoke test loads onboarding or dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyFinanceApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app loaded with Welcome screen
    expect(find.textContaining('Welcome to MyFinance'), findsOneWidget);
  });
}
