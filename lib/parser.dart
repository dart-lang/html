/// This library has a parser for HTML5 documents, that lets you parse HTML
/// easily from a script or server side application:
///
///     import 'package:html5lib/parser.dart' show parse;
///     import 'package:html5lib/dom.dart';
///     main() {
///       var document = parse(
///           '<body>Hello world! <a href="www.html5rocks.com">HTML5 rocks!');
///       print(document.outerHtml);
///     }
///
/// The resulting document you get back has a DOM-like API for easy tree
/// traversal and manipulation.
///
/// **DEPRECATED**. This package has been renamed `html`.
@Deprecated('Use the "html" package instead.')
library parser;

export 'package:html/parser.dart';
