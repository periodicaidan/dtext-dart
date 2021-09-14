library dtext;

import './parser.dart';

class DText {
  Document document;

  DText(this.document);

  factory DText.parse(String input) =>
      DText(documentParser.parse(input).value);
}