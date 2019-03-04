This is a pure [Dart][dart] [html5 parser][html5parse].
It's a port of [html5lib](https://github.com/html5lib/html5lib-python) from 
Python. 
Since it's 100% Dart you can use it safely from a script or server side app.

(Formerly known as `package:html5lib`.)

# Usage

Parsing HTML is easy!

```dart
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

main() {
  var document = parse(
      '<body>Hello world! <a href="www.html5rocks.com">HTML5 rocks!');
  print(document.outerHtml);
}
```

You can pass a String or list of bytes to `parse`.
There's also `parseFragment` for parsing a document fragment, and `HtmlParser`
if you want more low level control.

[dart]: https://www.dartlang.org/
[html5parse]: http://dev.w3.org/html5/spec/parsing.html
