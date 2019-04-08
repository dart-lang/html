import 'utf.dart';

// TODO(jmesserly): this function is conspicuously absent from dart:utf.
/// Returns true if the [bytes] starts with a UTF-8 byte order mark.
/// Since UTF-8 doesn't have byte order, it's somewhat of a misnomer, but it is
/// used in HTML to detect the UTF-
bool hasUtf8Bom(List<int> bytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : bytes.length;
  return (offset + 3) <= end &&
      bytes[offset] == 0xEF &&
      bytes[offset + 1] == 0xBB &&
      bytes[offset + 2] == 0xBF;
}

// TODO(jmesserly): it's unfortunate that this has to be one-shot on the entire
// file, but dart:utf does not expose stream-based decoders yet.
/// Decodes the [bytes] with the provided [encoding] and returns an iterable for
/// the codepoints. Supports the major unicode encodings as well as ascii and
/// and windows-1252 encodings.
Iterable<int> decodeBytes(String encoding, List<int> bytes) {
  switch (encoding) {
    case 'ascii':
      // TODO(jmesserly): this was taken from runtime/bin/string_stream.dart
      for (int byte in bytes) {
        if (byte > 127) {
          // TODO(jmesserly): ideally this would be DecoderException, like the
          // one thrown in runtime/bin/string_stream.dart, but we don't want to
          // depend on dart:io.
          throw FormatException("Illegal ASCII character $byte");
        }
      }
      return bytes;

    case 'utf-8':
      // NOTE: to match the behavior of the other decode functions, we eat the
      // utf-8 BOM here.

      var offset = 0;
      var length = bytes.length;

      if (hasUtf8Bom(bytes)) {
        offset += 3;
        length -= 3;
      }
      return decodeUtf8AsIterable(bytes, offset, length);

    default:
      throw ArgumentError('Encoding $encoding not supported');
  }
}

// TODO(jmesserly): use dart:utf once http://dartbug.com/6476 is fixed.
/// Returns the code points for the [input]. This works like [String.charCodes]
/// but it decodes UTF-16 surrogate pairs.
List<int> toCodepoints(String input) {
  var newCodes = <int>[];
  for (int i = 0; i < input.length; i++) {
    var c = input.codeUnitAt(i);
    if (0xD800 <= c && c <= 0xDBFF) {
      int next = i + 1;
      if (next < input.length) {
        var d = input.codeUnitAt(next);
        if (0xDC00 <= d && d <= 0xDFFF) {
          c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00);
          i = next;
        }
      }
    }
    newCodes.add(c);
  }
  return newCodes;
}
