import 'package:flutter_test/flutter_test.dart';
import 'package:quizrupi/main.dart';

void main() {
  testWidgets('QuizRupiApp basic instantiation smoke test', (WidgetTester tester) async {
    expect(const QuizRupiApp(), isA<QuizRupiApp>());
  });
}
