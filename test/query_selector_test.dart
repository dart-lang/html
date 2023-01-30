library query_selector_test;

import 'package:test/test.dart';
import 'package:html/dom.dart';

void main() {
  group('querySelector descendant', () {
    late Element el;

    setUp(() {
      el = Element.html('<div id="a" class="a"><div id="b"></div></div>');
    });

    test('descendant of type', () {
      expect(el.querySelector('div div')?.id, 'b');
    });

    test('descendant of class', () {
      expect(el.querySelector('.a div')?.id, 'b');
    });

    test('descendant of type and class', () {
      expect(el.querySelector('div.a div')?.id, 'b');
    });
  });
}
