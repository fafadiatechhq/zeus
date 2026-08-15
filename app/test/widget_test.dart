import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/main.dart';
import 'package:zeus/models/user.dart';
import 'package:zeus/providers/session_provider.dart';

void main() {
  testWidgets('Zeus app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(_GuestSession.new),
        ],
        child: const ZeusApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue'), findsOneWidget);
  });
}

class _GuestSession extends SessionNotifier {
  @override
  Future<User?> build() async => null;
}
