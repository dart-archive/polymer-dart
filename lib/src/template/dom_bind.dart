// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.template.dom_bind;

import 'dart:html';
// Needed to ensure `polymer.html` import.
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';

@CustomElementProxy('dom-bind', extendsTag: 'template')
class DomBind extends TemplateElement
    with CustomElementProxyMixin, PolymerBase {
  DomBind.created() : super.created();

  void render() {
    jsElement.callMethod('render');
  }

  /// Retrieve arbitrary values from the dom-bind instance.
  operator [](String key) => convertToDart(jsElement[key]);

  /// Set arbitrary values on the dom-bind instance. These will be  available
  /// to the template bindings.
  operator []=(String key, value) => set(key, value);
}
