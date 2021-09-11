import 'package:petitparser/petitparser.dart';

// Token classes

class OpenTag {
  String tagName;
  List<String> properties;
  String? attribute;

  OpenTag(this.tagName, this.properties, this.attribute);
  
  @override
  String toString() {
    return "OpenTag[ $tagName, $properties = $attribute ]";
  }
}

class CloseTag {
  String tagName;

  CloseTag(this.tagName);

  @override
  String toString() {
    return "CloseTag[ $tagName ]";
  }
}

class TaggedElement {
  String tagName;
  List<String> properties;
  String? attribute;
  dynamic children;

  TaggedElement(this.tagName, this.properties, this.attribute, this.children);

  @override
  String toString() {
    return "TaggedElement($tagName, $properties = $attribute)[$children]";
  }
}

class BoldElement {
  dynamic children;

  BoldElement(this.children);

  @override
  String toString() {
    return "Bold[ $children ]";
  }
}

class ItalicElement {
  dynamic children;

  ItalicElement(this.children);

  String toString() {
    return "Italic[ $children ]";
  }
}

class UnderlineElement {
  dynamic children;

  UnderlineElement(this.children);

  String toString() {
    return "Underline[ $children ]";
  }
}

class Document {
  List<dynamic> children;

  Document(this.children);

  @override
  String toString() {
    return "Document [\n\t${children.join('\n\t')}\n]";
  }
}

// Primitive control characters

final openBracketParser = char('[').trim();
final closeBracketParser = char(']').trim();
final forwardSlashParser = char('/').trim();
final equalSignParser = char('=').trim();
final commaParser = char(',').trim();

// Higher level control sequences

Parser _attrParser = (equalSignParser & pattern('^]').plus().flatten())
  .map((value) => value[1]);

Parser _propParser = (commaParser & pattern('^],=').plus().flatten())
    .map<String>((value) => value[1])
    .plus();

Parser _rawOpenTag(String tagName) =>
  (openBracketParser
    & string(tagName).trim()
    & _propParser.optional()
    & _attrParser.optional()
    & closeBracketParser);

Parser openTag(String tagName) =>
    _rawOpenTag(tagName)
      .map((tokens) => OpenTag(tokens[1], tokens[2] ?? [], tokens[3]));

Parser _rawCloseTag(String tagName) =>
    (openBracketParser
    & forwardSlashParser
    & string(tagName)
    & closeBracketParser);

Parser closeTag(String tagName) =>
    _rawCloseTag(tagName)
      .map((tokens) => CloseTag(tokens[2]));

Parser _rawTaggedElement(String tagName) =>
    (openTag(tagName)
    & (_rawCloseTag(tagName).not() & any()).star().flatten()
    & closeTag(tagName));

Parser taggedElement(String tagName) =>
    _rawTaggedElement(tagName)
        .map((tokens) {
          final openTag = tokens[0] as OpenTag;
          final children = tokens[1];
          return TaggedElement(openTag.tagName, openTag.properties,
              openTag.attribute, children);
    });

final boldParser = taggedElement('b')
  .map((elem) => BoldElement(elem.children));
final italicParser = taggedElement('i')
  .map((elem) => ItalicElement(elem.children));
final underlineParser = taggedElement('u')
  .map((elem) => UnderlineElement(elem.children));

final regularTextParser =
  ((['b', 'i', 'u'].map((a) => _rawOpenTag(a)))
      .toChoiceParser().not() & any()).plus().flatten();

Parser documentParser =
  (boldParser
    | italicParser
    | underlineParser
    | regularTextParser)
      .star()
      .map((tokens) => Document(tokens));





