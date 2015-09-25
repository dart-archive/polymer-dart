// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.template.dom_repeat;

import 'dart:html';
import 'dart:js';
import 'package:web_components/web_components.dart';
// Needed to ensure `polymer.html` import.
import 'package:polymer/polymer.dart';

@CustomElementProxy('dom-repeat', extendsTag: 'template')
class DomRepeat extends TemplateElement
    with CustomElementProxyMixin, PolymerBase {
  DomRepeat.created() : super.created();

  /// An array containing items determining how many instances of the template
  /// to stamp and that that each template instance should bind to.
  List get items => convertToDart(jsElement['items']);
  void set items(List newVal) => jsElement.callMethod('set', ['items', items]);

  /// The name of the variable to add to the binding scope for the array
  /// element associated with a given template instance.
  String get as => jsElement['as'];
  void set as(String newVal) {
    jsElement.callMethod('set', ['as', newVal]);
  }

  /// The name of the variable to add to the binding scope with the index
  /// for the row.  If `sort` is provided, the index will reflect the
  /// sorted order (rather than the original array order).
  String get indexAs => jsElement['indexAs'];
  void set indexAs(String newVal) {
    jsElement.callMethod('set', ['indexAs', newVal]);
  }

  /// A function that should determine the sort order of the items.  This
  /// property should either be provided as a string, indicating a method
  /// name on the element's host, or else be an actual function.  The
  /// function should match the sort function passed to `Array.sort`.
  /// Using a sort function has no effect on the underlying `items` array.
  dynamic get sort => convertToDart(jsElement['sort']);
  void set sort(newVal) {
    if (newVal is Function) {
      var original = newVal;
      newVal = (a, b) => original(convertToDart(a), convertToDart(b));
    }
    jsElement.callMethod('set', ['sort', newVal]);
  }

  /// A function that can be used to filter items out of the view.  This
  /// property should either be provided as a string, indicating a method
  /// name on the element's host, or else be an actual function.  The
  /// function should match the sort function passed to `Array.filter`.
  /// Using a filter function has no effect on the underlying `items` array.
  dynamic get filter => convertToDart(jsElement['filter']);
  void set filter(newVal) {
    if (newVal is Function) {
      var original = newVal;
      newVal = (element, [index, array]) =>
          original(convertToDart(element), index, convertToDart(array));
    }
    jsElement.callMethod('set', ['filter', newVal]);
  }

  /// When using a `filter` or `sort` function, the `observe` property
  /// should be set to a space-separated list of the names of item
  /// sub-fields that should trigger a re-sort or re-filter when changed.
  /// These should generally be fields of `item` that the sort or filter
  /// function depends on.
  String get observe => jsElement['observe'];
  void set observe(String newVal) {
    jsElement.callMethod('set', ['observe', newVal]);
  }

  /// When using a `filter` or `sort` function, the `delay` property
  /// determines a debounce time after a change to observed item
  /// properties that must pass before the filter or sort is re-run.
  /// This is useful in rate-limiting shuffing of the view when
  /// item changes may be frequent.
  num get delay => jsElement['delay'];
  void set delay(num newVal) {
    jsElement.callMethod('set', ['delay', newVal]);
  }

  void render() => jsElement.callMethod('render');

  /// Returns the template "model" associated with a given element, which
  /// serves as the binding scope for the template instance the element is
  /// contained in. A template model is an instance of `Polymer.Base`, and
  /// should be used to manipulate data associated with this template instance.
  ///
  /// Example:
  ///
  ///   var model = modelForElement(el);
  ///   if (model.index < 10) {
  ///     model.set('item.checked', true);
  ///   }
  DomRepeatModel modelForElement(Element element) {
    var proxy = jsElement.callMethod('modelForElement', [element]);
    if (proxy is HtmlElement) {
      proxy = new JsObject.fromBrowserObject(proxy);
    }
    return new DomRepeatModel(proxy);
  }

  /// Returns the actual `model.item` for an element.
  itemForElement(Element element) =>
      convertToDart(jsElement.callMethod('itemForElement', [element]));
}

// Dart wrapper for template models that come back from dom-repeat.
class DomRepeatModel extends Object with PolymerBase {
  final JsObject jsElement;

  get item => convertToDart(jsElement['item']);
  int get index => jsElement['index'];

  DomRepeatModel(this.jsElement);
  factory DomRepeatModel.fromEvent(e) {
    var proxy = new JsObject.fromBrowserObject(e)['model'];
    if (proxy is HtmlElement) {
      proxy = new JsObject.fromBrowserObject(proxy);
    }
    return new DomRepeatModel(proxy);
  }
}
