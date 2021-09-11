import '../lib/parser.dart';

void main() {
  final bold = '[b]this is bold!![/b] this text is normal [i]this is i t a l ic[/i]';

  final parsed = documentParser.parse(bold);

  print("Input: $bold");
  print(parsed);
}