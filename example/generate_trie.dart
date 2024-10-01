import 'package:dart_style/dart_style.dart';
import 'package:html/src/constants.dart';

/// Run this file to generate package:html/src/trie.dart
void main() {
  final root = <int, dynamic>{};
  for (final entity in entities.keys) {
    var node = root;
    for (final charCode in entity.codeUnits) {
      node = (node[charCode] ??= <int, dynamic>{}) as Map<int, dynamic>;
    }
  }
  final source =
      'const entitiesTrieRoot = $root;'.replaceAll('{}', '<int, dynamic>{}');
  final formatted = DartFormatter().format(source);
  // trimRight() because print adds its own newline
  print(formatted.trimRight());
}
