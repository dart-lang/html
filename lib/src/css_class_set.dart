// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): everything in this file is copied straight from "dart:html".
library html.dom.src;

import 'dart:collection';
import 'package:html/dom.dart';

class ElementCssClassSet extends CssClassSetImpl {
  final Element _element;

  ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    var classname = _element.className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    _element.className = s.join(' ');
  }
}

/** A Set that stores the CSS class names for an element. */
abstract class CssClassSet implements Set<String> {

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * If [shouldAdd] is true, then we always add that [value] to the element. If
   * [shouldAdd] is false then we always remove [value] from the element.
   */
  bool toggle(String value, [bool shouldAdd]);

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen;

  /**
   * Determine if this element contains the class [value].
   *
   * This is the Dart equivalent of jQuery's
   * [hasClass](http://api.jquery.com/hasClass/).
   */
  bool contains(Object value);

  /**
   * Add the class [value] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * If this corresponds to one element. Returns true if [value] was added to
   * the set, otherwise false.
   *
   * If this corresponds to many elements, null is always returned.
   */
  bool add(String value);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value);

  /**
   * Add all classes specified in [iterable] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   */
  void addAll(Iterable<String> iterable);

  /**
   * Remove all classes specified in [iterable] from element.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  void removeAll(Iterable<Object> iterable);

  /**
   * Toggles all classes specified in [iterable] on element.
   *
   * Iterate through [iterable]'s items, and add it if it is not on it, or
   * remove it if it is. This is the Dart equivalent of jQuery's
   * [toggleClass](http://api.jquery.com/toggleClass/).
   * If [shouldAdd] is true, then we always add all the classes in [iterable]
   * element. If [shouldAdd] is false then we always remove all the classes in
   * [iterable] from the element.
   */
  void toggleAll(Iterable<String> iterable, [bool shouldAdd]);
}

abstract class CssClassSetImpl implements CssClassSet {
  String toString() {
    return readClasses().join(' ');
  }

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * If [shouldAdd] is true, then we always add that [value] to the element. If
   * [shouldAdd] is false then we always remove [value] from the element.
   */
  bool toggle(String value, [bool shouldAdd]) {
    Set<String> s = readClasses();
    bool result = false;
    if (shouldAdd == null) shouldAdd = !s.contains(value);
    if (shouldAdd) {
      s.add(value);
      result = true;
    } else {
      s.remove(value);
    }
    writeClasses(s);
    return result;
  }

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen => false;

  // interface Iterable - BEGIN
  Iterator<String> get iterator => readClasses().iterator;
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    readClasses().forEach(f);
  }

  String join([String separator = ""]) => readClasses().join(separator);

  Iterable/*<T>*/ map/*<T>*/(/*=T*/ f(String e)) => readClasses().map(f);

  Iterable<String> where(bool f(String element)) => readClasses().where(f);

  Iterable/*<T>*/ expand/*<T>*/(Iterable/*<T>*/ f(String element)) => readClasses().expand(f);

  bool every(bool f(String element)) => readClasses().every(f);

  bool any(bool f(String element)) => readClasses().any(f);

  bool get isEmpty => readClasses().isEmpty;

  bool get isNotEmpty => readClasses().isNotEmpty;

  int get length => readClasses().length;

  String reduce(String combine(String value, String element)) {
    return readClasses().reduce(combine);
  }

  dynamic/*=T*/ fold/*<T>*/(var/*=T*/ initialValue,
      dynamic/*=T*/ combine(var/*=T*/ previousValue, String element)) {
    return readClasses().fold(initialValue, combine);
  }
  // interface Collection - END

  // interface Set - BEGIN
  /**
   * Determine if this element contains the class [value].
   *
   * This is the Dart equivalent of jQuery's
   * [hasClass](http://api.jquery.com/hasClass/).
   */
  bool contains(Object value) => readClasses().contains(value);

  /** Lookup from the Set interface. Not interesting for a String set. */
  String lookup(Object value) => contains(value) ? value as String : null;

  /**
   * Add the class [value] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   */
  bool add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough.
    return modify((s) => s.add(value));
  }

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value) {
    if (value is! String) return false;
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  /**
   * Add all classes specified in [iterable] to element.
   *
   * This is the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   */
  void addAll(Iterable<String> iterable) {
    // TODO - see comment above about validation.
    modify((s) => s.addAll(iterable));
  }

  /**
   * Remove all classes specified in [iterable] from element.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  void removeAll(Iterable<Object> iterable) {
    modify((s) => s.removeAll(iterable));
  }

  /**
   * Toggles all classes specified in [iterable] on element.
   *
   * Iterate through [iterable]'s items, and add it if it is not on it, or
   * remove it if it is. This is the Dart equivalent of jQuery's
   * [toggleClass](http://api.jquery.com/toggleClass/).
   * If [shouldAdd] is true, then we always add all the classes in [iterable]
   * element. If [shouldAdd] is false then we always remove all the classes in
   * [iterable] from the element.
   */
  void toggleAll(Iterable<String> iterable, [bool shouldAdd]) {
    iterable.forEach((e) => toggle(e, shouldAdd));
  }

  void retainAll(Iterable<Object> iterable) {
    modify((s) => s.retainAll(iterable));
  }

  void removeWhere(bool test(String name)) {
    modify((s) => s.removeWhere(test));
  }

  void retainWhere(bool test(String name)) {
    modify((s) => s.retainWhere(test));
  }

  bool containsAll(Iterable<Object> collection) =>
      readClasses().containsAll(collection);

  Set<String> intersection(Set<Object> other) =>
      readClasses().intersection(other);

  Set<String> union(Set<String> other) => readClasses().union(other);

  Set<String> difference(Set<Object> other) => readClasses().difference(other);

  String get first => readClasses().first;
  String get last => readClasses().last;
  String get single => readClasses().single;
  List<String> toList({bool growable: true}) =>
      readClasses().toList(growable: growable);
  Set<String> toSet() => readClasses().toSet();
  Iterable<String> take(int n) => readClasses().take(n);
  Iterable<String> takeWhile(bool test(String value)) =>
      readClasses().takeWhile(test);
  Iterable<String> skip(int n) => readClasses().skip(n);
  Iterable<String> skipWhile(bool test(String value)) =>
      readClasses().skipWhile(test);
  String firstWhere(bool test(String value), {String orElse()}) =>
      readClasses().firstWhere(test, orElse: orElse);
  String lastWhere(bool test(String value), {String orElse()}) =>
      readClasses().lastWhere(test, orElse: orElse);
  String singleWhere(bool test(String value)) =>
      readClasses().singleWhere(test);
  String elementAt(int index) => readClasses().elementAt(index);

  void clear() {
    modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *   s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  modify(f(Set<String> s)) {
    Set<String> s = readClasses();
    var ret = f(s);
    writeClasses(s);
    return ret;
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   * This is intended to be overridden by specific implementations.
   */
  Set<String> readClasses();

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   * This is intended to be overridden by specific implementations.
   */
  void writeClasses(Set<String> s);
}
