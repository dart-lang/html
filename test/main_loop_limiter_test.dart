import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  // Ideally the output should be the following markup:
  // `<button><p></p><p></p></button><button><p></p><p></p></button>`
  //
  // However, as it triggers the main loop to add errors forever, it will
  // trigger an OOM, unless we apply the limiter in the main loop.
  test('mixed order causes to trigger the main loop', () {
    expect(
        () => parseFragment('<button></p><p></button><button></p><p></button>'),
        throwsA(isA<UnimplementedError>().having((e) => e.message, 'message',
            'Reached maximum attempt count, giving up on token: button (null).')));
  });
}
