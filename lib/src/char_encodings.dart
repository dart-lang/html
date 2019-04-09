import 'dart:convert' show ascii, utf8;

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
      return ascii.decode(bytes).runes;

    case 'utf-8':
      // NOTE: To match the behavior of the other decode functions, we eat the
      // UTF-8 BOM here. This is the default behavior of `utf8.decode`.
      return utf8.decode(bytes).runes;

    default:
      throw ArgumentError('Encoding $encoding not supported');
  }
}

// TODO(jmesserly): use dart:utf once http://dartbug.com/6476 is fixed.
/// Returns the code points for the [input]. This works like [String.charCodes]
/// but it decodes UTF-16 surrogate pairs.
List<int> toCodepoints(String input) {
  return input.runes.toList();
}
