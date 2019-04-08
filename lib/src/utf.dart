// Large portions of this code where taken from https://github.com/dart-lang/utf

import "dart:collection";

const int _replacementCodepoint = 0xfffd;

const int _UNICODE_VALID_RANGE_MAX = 0x10ffff;
const int _UNICODE_UTF16_RESERVED_LO = 0xd800;
const int _UNICODE_UTF16_RESERVED_HI = 0xdfff;

const int _UTF8_ONE_BYTE_MAX = 0x7f;
const int _UTF8_TWO_BYTE_MAX = 0x7ff;
const int _UTF8_THREE_BYTE_MAX = 0xffff;

const int _UTF8_LO_SIX_BIT_MASK = 0x3f;

const int _UTF8_FIRST_BYTE_OF_TWO_BASE = 0xc0;
const int _UTF8_FIRST_BYTE_OF_THREE_BASE = 0xe0;
const int _UTF8_FIRST_BYTE_OF_FOUR_BASE = 0xf0;
const int _UTF8_FIRST_BYTE_OF_FIVE_BASE = 0xf8;
const int _UTF8_FIRST_BYTE_OF_SIX_BASE = 0xfc;

const int _UTF8_FIRST_BYTE_BOUND_EXCL = 0xfe;

/// Decodes the UTF-8 bytes as an iterable. Thus, the consumer can only convert
/// as much of the input as needed. Set the replacementCharacter to null to
/// throw an ArgumentError rather than replace the bad value.
Iterable<int> decodeUtf8AsIterable(List<int> bytes, int offset, int length) =>
    _IterableUtf8Decoder(bytes, offset, length);

/// Return type of [decodeUtf8AsIterable] and variants. The Iterable type
/// provides an iterator on demand and the iterator will only translate bytes
/// as requested by the user of the iterator. (Note: results are not cached.)
// TODO(floitsch): Consider removing the extend and switch to implements since
// that's cheaper to allocate.
class _IterableUtf8Decoder extends IterableBase<int> {
  final List<int> bytes;
  final int offset;
  final int length;

  _IterableUtf8Decoder(this.bytes, this.offset, this.length);

  _Utf8Decoder get iterator => _Utf8Decoder(bytes, offset, length);
}

/// Provides an iterator of Unicode codepoints from UTF-8 encoded bytes. The
/// parameters can set an offset into a list of bytes (as int), limit the length
/// of the values to be decoded, and override the default Unicode replacement
/// character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value. The return value
/// from this method can be used as an Iterable (e.g. in a for-loop).
class _Utf8Decoder implements Iterator<int> {
  final _ListRangeIterator utf8EncodedBytesIterator;
  int _current;

  _Utf8Decoder(List<int> utf8EncodedBytes, int offset, int length)
      : utf8EncodedBytesIterator =
            (_ListRange(utf8EncodedBytes, offset, length)).iterator;

  _Utf8Decoder._fromListRangeIterator(_ListRange source)
      : utf8EncodedBytesIterator = source.iterator;

  /// Decode the remaininder of the characters in this decoder
  /// into a [List<int>].
  List<int> decodeRest() {
    List<int> codepoints = List<int>(utf8EncodedBytesIterator.remaining);
    int i = 0;
    while (moveNext()) {
      codepoints[i++] = current;
    }
    if (i == codepoints.length) {
      return codepoints;
    } else {
      List<int> truncCodepoints = List<int>(i);
      truncCodepoints.setRange(0, i, codepoints);
      return truncCodepoints;
    }
  }

  int get current => _current;

  bool moveNext() {
    _current = null;

    if (!utf8EncodedBytesIterator.moveNext()) return false;

    int value = utf8EncodedBytesIterator.current;
    int additionalBytes = 0;

    if (value < 0) {
      if (_replacementCodepoint != null) {
        _current = _replacementCodepoint;
        return true;
      } else {
        throw ArgumentError(
            "Invalid UTF8 at ${utf8EncodedBytesIterator.position}");
      }
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      _current = value;
      return true;
    } else if (value < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
      if (_replacementCodepoint != null) {
        _current = _replacementCodepoint;
        return true;
      } else {
        throw ArgumentError(
            "Invalid UTF8 at ${utf8EncodedBytesIterator.position}");
      }
    } else if (value < _UTF8_FIRST_BYTE_OF_THREE_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_TWO_BASE;
      additionalBytes = 1;
    } else if (value < _UTF8_FIRST_BYTE_OF_FOUR_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_THREE_BASE;
      additionalBytes = 2;
    } else if (value < _UTF8_FIRST_BYTE_OF_FIVE_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_FOUR_BASE;
      additionalBytes = 3;
    } else if (value < _UTF8_FIRST_BYTE_OF_SIX_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_FIVE_BASE;
      additionalBytes = 4;
    } else if (value < _UTF8_FIRST_BYTE_BOUND_EXCL) {
      value -= _UTF8_FIRST_BYTE_OF_SIX_BASE;
      additionalBytes = 5;
    } else if (_replacementCodepoint != null) {
      _current = _replacementCodepoint;
      return true;
    } else {
      throw ArgumentError(
          "Invalid UTF8 at ${utf8EncodedBytesIterator.position}");
    }
    int j = 0;
    while (j < additionalBytes && utf8EncodedBytesIterator.moveNext()) {
      int nextValue = utf8EncodedBytesIterator.current;
      if (nextValue > _UTF8_ONE_BYTE_MAX &&
          nextValue < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
        value = ((value << 6) | (nextValue & _UTF8_LO_SIX_BIT_MASK));
      } else {
        // if sequence-starting code unit, reposition cursor to start here
        if (nextValue >= _UTF8_FIRST_BYTE_OF_TWO_BASE) {
          utf8EncodedBytesIterator.backup();
        }
        break;
      }
      j++;
    }
    bool validSequence = (j == additionalBytes &&
        (value < _UNICODE_UTF16_RESERVED_LO ||
            value > _UNICODE_UTF16_RESERVED_HI));
    bool nonOverlong = (additionalBytes == 1 && value > _UTF8_ONE_BYTE_MAX) ||
        (additionalBytes == 2 && value > _UTF8_TWO_BYTE_MAX) ||
        (additionalBytes == 3 && value > _UTF8_THREE_BYTE_MAX);
    bool inRange = value <= _UNICODE_VALID_RANGE_MAX;
    if (validSequence && nonOverlong && inRange) {
      _current = value;
      return true;
    } else if (_replacementCodepoint != null) {
      _current = _replacementCodepoint;
      return true;
    } else {
      throw ArgumentError(
          "Invalid UTF8 at ${utf8EncodedBytesIterator.position - j}");
    }
  }
}

/// _ListRange in an internal type used to create a lightweight Interable on a
/// range within a source list. DO NOT MODIFY the underlying list while
/// iterating over it. The results of doing so are undefined.
// TODO(floitsch): Consider removing the extend and switch to implements since
// that's cheaper to allocate.
class _ListRange extends IterableBase<int> {
  final List<int> _source;
  final int _offset;
  final int _length;

  _ListRange(List<int> source, [int offset = 0, int length])
      : _source = source,
        _offset = offset,
        _length = (length == null ? source.length - offset : length) {
    if (_offset < 0 || _offset > _source.length) {
      throw RangeError.value(_offset);
    }
    if (_length != null && (_length < 0)) {
      throw RangeError.value(_length);
    }
    if (_length + _offset > _source.length) {
      throw RangeError.value(_length + _offset);
    }
  }

  _ListRangeIterator get iterator =>
      _ListRangeIteratorImpl(_source, _offset, _offset + _length);

  int get length => _length;
}

/// The ListRangeIterator provides more capabilities than a standard iterator,
/// including the ability to get the current position, count remaining items,
/// and move forward/backward within the iterator.
abstract class _ListRangeIterator implements Iterator<int> {
  bool moveNext();

  int get current;

  int get position;

  void backup([int by]);

  int get remaining;

  void skip([int count]);
}

class _ListRangeIteratorImpl implements _ListRangeIterator {
  final List<int> _source;
  int _offset;
  final int _end;

  _ListRangeIteratorImpl(this._source, int offset, this._end)
      : _offset = offset - 1;

  int get current => _source[_offset];

  bool moveNext() => ++_offset < _end;

  int get position => _offset;

  void backup([int by = 1]) {
    _offset -= by;
  }

  int get remaining => _end - _offset - 1;

  void skip([int count = 1]) {
    _offset += count;
  }
}
