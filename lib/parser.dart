import 'package:petitparser/petitparser.dart';

// Utils

extension _JoinTabbed on Iterable<String> {
  String joinTabbed({String sep = '\n'}) =>
    map((e) => '\t$e')
        .join(sep);
}

String _joinChildren(List<DocumentNode> children) =>
    children
        .map((c) => c.toString().split('\n').joinTabbed())
        .join('\n');

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

abstract class DocumentNode {}

class TextNode extends DocumentNode {
  String content;

  TextNode(this.content);

  @override
  String toString() {
    return "Text( $content )";
  }
}

class BoldElement extends DocumentNode {
  List<DocumentNode> children;

  BoldElement(this.children);

  @override
  String toString() {
    return "<b>\n${_joinChildren(children)}\n</b>";
  }
}

class ItalicElement extends DocumentNode {
  List<DocumentNode> children;

  ItalicElement(this.children);

  String toString() {
    return "<i>\n${_joinChildren(children)}\n</i>";
  }
}

class UnderlineElement extends DocumentNode {
  List<DocumentNode> children;

  UnderlineElement(this.children);

  String toString() {
    return "<u>${_joinChildren(children)}</u>";
  }
}

class StrikethroughElement extends DocumentNode {
  List<DocumentNode> children;

  StrikethroughElement(this.children);

  @override
  String toString() {
    return "<s>\n${_joinChildren(children)}\n</s>";
  }
}

class SuperscriptElement extends DocumentNode {
  List<DocumentNode> children;

  SuperscriptElement(this.children);

  @override
  String toString() {
    return "<sup>\n${_joinChildren(children)}\n</sup>";
  }
}

class SubscriptElement extends DocumentNode {
  List<DocumentNode> children;

  SubscriptElement(this.children);

  @override
  String toString() {
    return "<sub>\n${_joinChildren(children)}\n</sub>";
  }
}

class QuoteElement extends DocumentNode {
  List<DocumentNode> children;

  QuoteElement(this.children);

  @override
  String toString() {
    return "<blockquote>\n${_joinChildren(children)}\n</blockquote>";
  }
}

class SpoilerElement extends DocumentNode {
  List<DocumentNode> children;

  SpoilerElement(this.children);

  @override
  String toString() {
    return '<spoiler>\n${_joinChildren(children)}\n</spoiler>';
  }
}

class ColorElement extends DocumentNode {
  String color;
  List<DocumentNode> children;

  ColorElement(this.color, this.children);

  @override
  String toString() {
    return '<span style="color: $color">\n${_joinChildren(children)}\n</span>';
  }
}

class CodeElement extends DocumentNode {
  String content;

  CodeElement(this.content);

  @override
  String toString() {
    return '<code>$content</code>';
  }
}

class SectionElement extends DocumentNode {
  String title;
  bool isExtended;
  List<DocumentNode> children;

  SectionElement(this.title, this.isExtended, this.children);

  @override
  String toString() {
    return '<section title="${title}" extended=$isExtended>\n${_joinChildren(children)}\n</section>';
  }
}

class Document {
  List<DocumentNode> children;

  Document(this.children);

  @override
  String toString() {
    return "Document [\n${_joinChildren(children)}\n]";
  }
}

// Primitive control characters

final openBracketParser = char('[');
final closeBracketParser = char(']');
final forwardSlashParser = char('/');
final equalSignParser = char('=');
final commaParser = char(',');
final backtickParser = char('`');

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

Parser<TaggedElement> taggedElement(String tagName) =>
    _rawTaggedElement(tagName)
        .map((tokens) {
          final openTag = tokens[0] as OpenTag;
          final children = documentNodeParser.star().parse(tokens[1]).value;
          return TaggedElement(openTag.tagName, openTag.properties,
              openTag.attribute, children);
    });

// Defining tags

const _tagNames = ['b', 'i', 'u', 's', 'sup', 'sub', 'spoiler', 'quote',
  'color', 'section', 'table', 'thead', 'tr', 'th', 'tbody', 'td'];

final boldParser = taggedElement('b')
  .map((elem) => BoldElement(elem.children));
final italicParser = taggedElement('i')
  .map((elem) => ItalicElement(elem.children));
final underlineParser = taggedElement('u')
  .map((elem) => UnderlineElement(elem.children));
final strikethroughParser = taggedElement('s')
  .map((elem) => StrikethroughElement(elem.children));
final superscriptParser = taggedElement('sup')
  .map((elem) => SuperscriptElement(elem.children));
final subscriptParser = taggedElement('sub')
  .map((elem) => SubscriptElement(elem.children));
final spoilerParser = taggedElement('spoiler')
  .map((elem) => SpoilerElement(elem.children));
final quoteParser = taggedElement('quote')
  .map((elem) => QuoteElement(elem.children));
final colorParser = taggedElement('color')
  .map((elem) => ColorElement(elem.attribute!, elem.children));
final sectionParser = taggedElement('section')
  .map((elem) =>
    SectionElement(
        elem.attribute ?? '',
        elem.properties.any((p) => p == 'extended'),
        elem.children
    )
  );
final Parser<CodeElement> _codeParserWithTags =
    _rawTaggedElement('code')
      .map((values) => CodeElement(values[1]));
final Parser<CodeElement> _codeParserWithBackticks =
    (backtickParser
    & pattern('^`').star().flatten()
    & backtickParser)
      .map((values) => CodeElement(values[1]));
final Parser<CodeElement> codeParser =
    (_codeParserWithTags | _codeParserWithBackticks)
     .cast();



final regularTextParser =
  ((_tagNames.map(_rawOpenTag)).toChoiceParser().not()
  & any())
      .plus()
      .flatten()
      .map((value) => TextNode(value));

List<Parser<DocumentNode>> elementParsers = [
  boldParser,
  italicParser,
  underlineParser,
  strikethroughParser,
  superscriptParser,
  subscriptParser,
  colorParser,
  sectionParser,
  // This should always go last
  regularTextParser,
];

Parser<DocumentNode> documentNodeParser =
  elementParsers
      .toChoiceParser()
      .cast<DocumentNode>();

Parser<Document> documentParser =
  documentNodeParser
      .star()
      .map((tokens) => Document(tokens));





