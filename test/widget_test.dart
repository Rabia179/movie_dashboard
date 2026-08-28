import 'package:flutter_test/flutter_test.dart';
import 'package:movie_dashboard/main.dart';

void main() {
  testWidgets('Movie Dashboard app starts', (tester) async {
    await tester.pumpWidget(const MovieDashboard());
    await tester.pump();

    expect(find.byType(MovieDashboard), findsOneWidget);
  });
}