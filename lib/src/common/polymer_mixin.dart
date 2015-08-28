// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';
import 'package:polymer_interop/polymer_interop.dart' show Polymer, PolymerDom;
import 'js_proxy.dart';


/// Basic api for re-using the polymer js prototypes.
abstract class PolymerMixin implements JsProxy {
  JsObject _proxy;

  JsObject get jsElement {
    if (_proxy == null) {
      _proxy = new JsObject.fromBrowserObject(this);
      _proxy['__data__'] = jsProxy;
    }
    return _proxy;
  }

  void polymerCreated() {
    // Use a cache for js proxy values.
    useCache = true;
    jsElement.callMethod('originalPolymerCreatedCallback');
  }

  /// Sets a value on an attribute path, and notifies of changes.
  void set(String path, value) =>
      jsElement.callMethod('set', [path, jsValue(value)]);

  /// Add `item` to a list at `path`.
  void add(String path, item) {
    jsElement.callMethod('push', [path, jsValue(item)]);
  }

  /// Add `items` to a list at `path`.
  void addAll(String path, Iterable items) {
    jsElement.callMethod(
        'push', [path]..addAll(items.map((item) => jsValue(item))));
  }

  /// Remove all items from a list at `path`.
  void clear(String path) {
    jsElement.callMethod('splice', [path, 0, jsElement[path].length]);
  }

  /// Sets the objects in the range `start` inclusive to `end` exclusive to the
  /// given `fillValue` on the list at `path`.
  void fillRange(String path, int start, int end, [fillValue]) {
    var numToFill = end - start;
    jsElement.callMethod(
        'splice',
        [path, start, numToFill]
          ..addAll(new List.filled(numToFill, jsValue(fillValue))));
  }

  /// Gets a value at `path`.
  get(String path) => dartValue(jsElement.callMethod('get', [path]));

  /// Inserts `element` at position `index` to the list at `path`.
  void insert(String path, int index, element) {
    jsElement.callMethod('splice', [path, index, 0, jsValue(element)]);
  }

  /// Inserts `elements` at position `index` to the list at `path`.
  void insertAll(String path, int index, Iterable elements) {
    jsElement.callMethod(
        'splice',
        [path, index, 0]..addAll(elements.map((element) => jsValue(element))));
  }

  /// Removes the first occurrence of `value` from the list at `path`.
  /// Returns true if value was in the list, false otherwise.
  /// **Note**: Renamed from `remove` because that conflicts with
  /// HtmlElement.remove.
  bool removeItem(String path, value) {
    List list = get(path);
    var index = list.indexOf(value);
    /// Assumes the lists are in sync! We are in lots of trouble if they aren't
    /// though, and verifying it is a lot more expensive.
    jsElement.callMethod('splice', [path, index, 1]);
    return true;
  }

  /// Removes the item at `index` from the list at `path`. Returns the removed
  /// element.
  dynamic removeAt(String path, int index) {
    return dartValue(jsElement.callMethod('splice', [path, index, 1])[0]);
  }

  /// Removes the last from the list at `path`. Returns the removed element.
  dynamic removeLast(String path) {
    return dartValue(jsElement.callMethod('pop', [path]));
  }

  /// Removes the objects in the range `start` inclusive to `end` exclusive from
  /// the list at `path`.
  void removeRange(String path, int start, int end) {
    jsElement.callMethod('splice', [path, start, end - start]);
  }

  /// Removes all objects from the list at `path` that satisfy `test`.
  /// TODO(jakemac): Optimize by removing whole ranges?
  void removeWhere(String path, bool test(element)) {
    var list = get(path);
    var indexesToRemove = [];
    for (int i = 0; i < list.length; i++) {
      if (test(list[i])) indexesToRemove.add(i);
    }
    for (int index in indexesToRemove.reversed) {
      removeAt(path, index);
    }
  }

  /// Removes the objects in the range `start` inclusive to `end` exclusive and
  /// inserts the contents of `replacement` in its place for the list at `path`.
  void replaceRange(String path, int start, int end, Iterable replacement) {
    jsElement.callMethod(
        'splice',
        [path, start, end - start]
          ..addAll(replacement.map((element) => jsValue(element))));
  }

  /// Removes all objects from the list at `path` that fail to satisfy `test`.
  void retainWhere(String path, bool test(element)) {
    removeWhere(path, (element) => !test(element));
  }

  /// Overwrites objects in the list at `path` with the objects of `iterable`,
  /// starting at position `index` in this list.
  void setAll(String path, int index, Iterable iterable) {
    var list = get(path);
    var numToRemove = list.length - index;
    jsElement.callMethod(
        'splice',
        [path, index, numToRemove]
          ..addAll(iterable.map((element) => jsValue(element))));
  }

  /// Copies the objects of `iterable`, skipping `skipCount` objects first, into
  /// the range `start`, inclusive, to `end`, exclusive, of the list at `path`.
  void setRange(
      String path, int start, int end, Iterable iterable, [int skipCount = 0]) {
    int numToReplace = end - start;
    jsElement.callMethod(
      'splice',
      [path, start, numToReplace]
        ..addAll(
          iterable
            .skip(skipCount)
            .take(numToReplace)
            .map((element) => jsValue(element))));
  }

  /// TODO(jakemac): Sort? What is the best way to accomplish this on the js
  /// side of things in polymer?
}

class Foo extends Object with Polymer, Polymer, Polymer {}
