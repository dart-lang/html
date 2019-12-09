/// Support code for the tests in this directory.
library support;

import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:html/src/treebuilder.dart';
import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';

typedef TreeBuilderFactory = TreeBuilder Function(bool namespaceHTMLElements);

Map<String, TreeBuilderFactory> _treeTypes;
Map<String, TreeBuilderFactory> get treeTypes {
  // TODO(jmesserly): add DOM here once it's implemented
  _treeTypes ??= {'simpletree': (useNs) => TreeBuilder(useNs)};
  return _treeTypes;
}

final testDir = p.join(p.dirname(p.fromUri(Platform.packageConfig)), 'test');

final testDataDir = p.join(testDir, 'data');

Iterable<String> getDataFiles(String subdirectory) {
  var dir = Directory(p.join(testDataDir, subdirectory));
  return dir.listSync().whereType<File>().map((f) => f.path);
}

// TODO(jmesserly): make this class simpler. We could probably split on
// "\n#" instead of newline and remove a lot of code.
class TestData extends IterableBase<Map> {
  final String _text;
  final String newTestHeading;

  TestData(String filename, [this.newTestHeading = 'data'])
      // Note: can't use readAsLinesSync here because it splits on \r
      : _text = File(filename).readAsStringSync();

  // Note: in Python this was a generator, but since we can't do that in Dart,
  // it's easier to convert it into an upfront computation.
  @override
  Iterator<Map> get iterator => _getData().iterator;

  List<Map> _getData() {
    var data = <String, String>{};
    String key;
    var result = <Map>[];
    var lines = _text.split('\n');
    // Remove trailing newline to match Python
    if (lines.last == '') {
      lines.removeLast();
    }
    for (var line in lines) {
      var heading = sectionHeading(line);
      if (heading != null) {
        if (data.isNotEmpty && heading == newTestHeading) {
          // Remove trailing newline
          data[key] = data[key].substring(0, data[key].length - 1);
          result.add(normaliseOutput(data));
          data = <String, String>{};
        }
        key = heading;
        data[key] = '';
      } else if (key != null) {
        data[key] = '${data[key]}$line\n';
      }
    }

    if (data.isNotEmpty) {
      result.add(normaliseOutput(data));
    }
    return result;
  }

  /// If the current heading is a test section heading return the heading,
  /// otherwise return null.
  static String sectionHeading(String line) {
    return line.startsWith('#') ? line.substring(1).trim() : null;
  }

  static Map normaliseOutput(Map data) {
    // Remove trailing newlines
    data.forEach((key, value) {
      if (value.endsWith('\n')) {
        data[key] = value.substring(0, value.length - 1);
      }
    });
    return data;
  }
}

/// Serialize the [document] into the html5 test data format.
String testSerializer(document) {
  return (TestSerializer()..visit(document)).toString();
}

/// Serializes the DOM into test format. See [testSerializer].
class TestSerializer extends TreeVisitor {
  final StringBuffer _str;
  int _indent = 0;
  String _spaces = '';

  TestSerializer() : _str = StringBuffer();

  @override
  String toString() => _str.toString();

  int get indent => _indent;

  set indent(int value) {
    if (_indent == value) return;

    var arr = List<int>(value);
    for (var i = 0; i < value; i++) {
      arr[i] = 32;
    }
    _spaces = String.fromCharCodes(arr);
    _indent = value;
  }

  void _newline() {
    if (_str.length > 0) _str.write('\n');
    _str.write('|$_spaces');
  }

  @override
  void visitNodeFallback(Node node) {
    _newline();
    _str.write(node);
    visitChildren(node);
  }

  @override
  void visitChildren(Node node) {
    indent += 2;
    for (var child in node.nodes) {
      visit(child);
    }
    indent -= 2;
  }

  @override
  void visitDocument(node) => _visitDocumentOrFragment(node);

  void _visitDocumentOrFragment(node) {
    indent += 1;
    for (var child in node.nodes) {
      visit(child);
    }
    indent -= 1;
  }

  @override
  void visitDocumentFragment(DocumentFragment node) =>
      _visitDocumentOrFragment(node);

  @override
  void visitElement(Element node) {
    _newline();
    _str.write(node);
    if (node.attributes.isNotEmpty) {
      indent += 2;
      var keys = List.from(node.attributes.keys);
      keys.sort((x, y) => x.compareTo(y));
      for (var key in keys) {
        var v = node.attributes[key];
        if (key is AttributeName) {
          AttributeName attr = key;
          key = '${attr.prefix} ${attr.name}';
        }
        _newline();
        _str.write('$key="$v"');
      }
      indent -= 2;
    }
    visitChildren(node);
  }
}
