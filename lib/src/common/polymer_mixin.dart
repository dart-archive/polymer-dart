// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';
import 'package:polymer_interop/polymer_interop.dart' show Polymer, PolymerDom;
import 'package:web_components/web_components.dart';
import 'js_proxy.dart';


/// Basic api for re-using the polymer js prototypes.
abstract class PolymerMixin implements JsProxy, CustomElementProxyMixin {
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

  /// Notify of a change to a property path.
  void notifyPath(String path, value) =>
    jsElement.callMethod('notifyPath', [path, jsValue(value)]);

  /// Add `item` to a list at `path`.
  void add(String path, item) {
    _readPath(path)..add(item);
    jsElement.callMethod('push', [path, jsValue(item)]);
  }

  /// Add `items` to a list at `path`.
  void addAll(String path, Iterable items) {
    _readPath(path)..addAll(items);
    jsElement.callMethod(
        'push', [path]..addAll(items.map((item) => jsValue(item))));
  }

  /// Remove all items from a list at `path`.
  void clear(String path) {
    _readPath(path)..clear();
    jsElement.callMethod('splice', [path, 0, jsElement[path].length]);
  }

  /// Sets the objects in the range `start` inclusive to `end` exclusive to the
  /// given `fillValue` on the list at `path`.
  void fillRange(String path, int start, int end, [fillValue]) {
    _readPath(path)
      ..fillRange(start, end, fillValue);
    var numToFill = end - start;
    jsElement.callMethod(
        'splice',
        [path, start, numToFill]
          ..addAll(new List.filled(numToFill, jsValue(fillValue))));
  }

  /// Inserts `element` at position `index` to the list at `path`.
  void insert(String path, int index, element) {
    _readPath(path)..insert(index, element);
    jsElement.callMethod('splice', [path, index, 0, jsValue(element)]);
  }

  /// Inserts `elements` at position `index` to the list at `path`.
  void insertAll(String path, int index, Iterable elements) {
    _readPath(path)..insertAll(index, elements);
    jsElement.callMethod(
        'splice',
        [path, index, 0]..addAll(elements.map((element) => jsValue(element))));
  }

  /// Removes the first occurrence of `value` from the list at `path`.
  /// Returns true if value was in the list, false otherwise.
  /// **Note**: Renamed from `remove` because that conflicts with
  /// HtmlElement.remove.
  bool removeItem(String path, value) {
    List list = _readPath(path);
    var index = list.indexOf(value);
    if (index == -1) return false;
    list.remove(value);
    /// Assumes the lists are in sync! We are in lots of trouble if they aren't
    /// though, and verifying it is a lot more expensive.
    jsElement.callMethod('splice', [path, index, 1]);
    return true;
  }

  /// Removes the item at `index` from the list at `path`. Returns the removed
  /// element.
  dynamic removeAt(String path, int index) {
    var element = _readPath(path).removeAt(index);
    jsElement.callMethod('splice', [path, index, 1]);
    return element;
  }

  /// Removes the last from the list at `path`. Returns the removed element.
  dynamic removeLast(String path) {
    var element = _readPath(path).removeLast();
    jsElement.callMethod('pop', [path]);
    return element;
  }

  /// Removes the objects in the range `start` inclusive to `end` exclusive from
  /// the list at `path`.
  void removeRange(String path, int start, int end) {
    _readPath(path)..removeRange(start, end);
    jsElement.callMethod('splice', [path, start, end - start]);
  }

  /// Removes all objects from the list at `path` that satisfy `test`.
  /// TODO(jakemac): Optimize by removing whole ranges?
  void removeWhere(String path, bool test(element)) {
    var list = _readPath(path);
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
    _readPath(path)
      ..replaceRange(start, end, replacement);
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
    var list = _readPath(path);
    var numToRemove = list.length - index;
    list..setAll(index, iterable);
    jsElement.callMethod(
        'splice',
        [path, index, numToRemove]
          ..addAll(iterable.map((element) => jsValue(element))));
  }

  /// Copies the objects of `iterable`, skipping `skipCount` objects first, into
  /// the range `start`, inclusive, to `end`, exclusive, of the list at `path`.
  void setRange(
      String path, int start, int end, Iterable iterable, [int skipCount = 0]) {
    _readPath(path)
      ..setRange(start, end, iterable, skipCount);
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

  // TODO(jakemac): investigate wrapping this object in something that
  // implements map, see
  // https://chromiumcodereview.appspot.com/23291005/patch/25001/26002 for an
  // example of this.
  JsObject get $ => jsElement[r'$'];

  /// The shadow or shady root, depending on which system is in use.
  DocumentFragment get root => jsElement['root'];

  /// Fire a custom event.
  CustomEvent fire( String type, {
      dynamic detail, bool canBubble: true, bool cancelable: true, Node node}) {
    var options = {
      'node': node,
      'bubbles': canBubble,
      'cancelable': cancelable,
    };
    return jsElement.callMethod(
        'fire', [type, jsValue(detail), jsValue(options)]);
  }

  // Gets an item at `path`, assuming all elements except the final item are
  // annotated with [jsProxyReflectable].
  _readPath(String path) {
    var parts = path.split('.');
    var obj = jsProxyReflectable.reflect(this).invokeGetter(parts[0]);
    for (int i = 1; i < parts.length; i++) {
      if (obj == null) return null;
      var mirror;
      try {
        mirror = jsProxyReflectable.reflect(this);
      } catch (e) {
        throw 'All elements on path $path must be annoted with '
          '@jsProxyReflectable, `${parts.length[i - 1]}` was not.';
      }
      obj = mirror.invokeGetter(parts[i]);
    }
    return obj;
  }
}

class Foo extends Object with Polymer, Polymer, Polymer {}
