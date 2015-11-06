// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.template.array_selector;

import 'dart:html';
import 'package:web_components/web_components.dart';
import 'package:polymer/polymer.dart';

@CustomElementProxy('array-selector')
class ArraySelector extends HtmlElement
    with CustomElementProxyMixin, PolymerBase {
  ArraySelector.created() : super.created();

  /// An array containing items from which selection will be made.
  List get items => convertToDart(jsElement['items']);
  void set items(List newVal) => jsElement.callMethod('set', ['items', items]);

  /// When `multi` is true, this is an array that contains any selected.
  /// When `multi` is false, this is the currently selected item, or `null`
  /// if no item is selected.
  dynamic get selected => convertToDart(jsElement['selected']);

  /// When `multi` is false, this is the currently selected item, or `null`
  /// if no item is selected.
  dynamic get selectedItem => convertToDart(jsElement['selectedItem']);
  void set selectedItem(newVal) {
    jsElement['selectedItem'] = convertToJs(newVal);
  }

  /// When `true`, calling `select` on an item that is already selected
  /// will deselect the item.
  bool get toggle => jsElement['toggle'];
  void set toggle(bool newVal) {
    jsElement.callMethod('set', ['toggle', newVal]);
  }

  /// When `true`, multiple items may be selected at once (in this case,
  /// `selected` is an array of currently selected items).  When `false`,
  /// only one item may be selected at a time.
  bool get multi => jsElement['multi'];
  void set multi(bool newVal) {
    jsElement.callMethod('set', ['multi', newVal]);
  }

  /// Deselects the given item if it is already selected.
  void deselect(item) => jsElement.callMethod('deselect', [convertToJs(item)]);

  /// Selects the given item.  When `toggle` is true, this will automatically
  /// deselect the item if already selected.
  void select(item) => jsElement.callMethod('select', [convertToJs(item)]);
}
