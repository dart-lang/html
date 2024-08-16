import 'package:html/src/constants.dart';
import 'package:html/src/trie.dart';
import 'package:test/test.dart';

/// Some tests to ensure the [entities] and [entitiesTrieRoot] are in sync.
void main() {
  test('All entities are in trie', () {
    for (final entity in entities.keys) {
      Map<int, dynamic>? node = entitiesTrieRoot;
      for (final codeUnit in entity.codeUnits) {
        node = node?[codeUnit] as Map<int, dynamic>?;
      }
      expect(node, isNotNull, reason: 'trie should contain $entity');
    }
  });

  test('Trie does not contain non-entity paths', () {
    Map<int, dynamic> deepCopyMapOfMaps(Map<int, dynamic> src) {
      return {
        for (final pair in src.entries)
          pair.key: deepCopyMapOfMaps(pair.value as Map<int, dynamic>)
      };
    }

    final root = deepCopyMapOfMaps(entitiesTrieRoot);
    // Iterate from longest to shortest to clean up trie as we go
    outer:
    for (final entityString in entities.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length))) {
      final codeUnits = entityString.codeUnits;
      var node = root;
      final path = [root];
      for (final codeUnit in codeUnits) {
        final newNode = node[codeUnit] as Map<int, dynamic>?;
        if (newNode == null) {
          // This path was already cleaned up, this entityString must be a prefix of a longer one.
          continue outer;
        }
        path.add(node = newNode);
      }
      for (var i = codeUnits.length - 1; i >= 0; i--) {
        if (path[i + 1].isEmpty) {
          path[i].remove(codeUnits[i]);
        }
      }
    }
    expect(root, isEmpty, reason: 'trie root contains some dead paths');
  });
}
