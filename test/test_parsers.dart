import '../lib/parser.dart';

void main() {
  final bold = '[b][i] this is bold AND italic [/i][s]this is just bold[/s][/b]'
      '\n\n[color=red]OMG this text is red!![/color]';

  final section = '[section]this is a section[/section]'
      '[section,extended]this one is extended[/section]'
      '[section,extended=The Title]and this one has a title[/section]';

  final parsed = documentParser.parse(section);

  print("Input: $section");
  print(parsed);
}