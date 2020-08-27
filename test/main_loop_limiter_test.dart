import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  // Ideally the output should be the following markup:
  // `<button><p></p><p></p></button><button><p></p><p></p></button>`
  //
  // However, as it triggers the main loop to add errors forever, it will
  // trigger an OOM, unless we apply the limiter in the main loop.
  test('mixed order causes to trigger the main loop', () {
    final parser =
        HtmlParser('<button></p><p></button><button></p><p></button>');
    final doc = parser.parseFragment();
    expect(doc.outerHtml, '<button><p></p><p></p><p></p></button>');
    // The number of reported errors may change as we change the limiter's
    // parameter.
    expect(parser.errors, hasLength(203));
    expect(parser.errors.take(11).map((e) => e.message).toList(), [
      'Unexpected end tag (p). Ignored.',
      'Unexpected end tag (button). Ignored.',
      'Unexpected start tag (button) implies end tag (button).',
      'Unexpected end tag (button). Ignored.',
      'Unexpected start tag (button) implies end tag (button).',
      'Unexpected end tag (button). Ignored.',
      'Unexpected start tag (button) implies end tag (button).',
      'Unexpected end tag (button). Ignored.',
      'Unexpected start tag (button) implies end tag (button).',
      'Unexpected end tag (button). Ignored.',
      'Unexpected start tag (button) implies end tag (button).',
    ]);
  });
}
