// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.template.dom_if;

import 'dart:html';
// Needed to ensure `polymer.html` import.
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart';

@CustomElementProxy('dom-if', extendsTag: 'template')
class DomIf extends TemplateElement with CustomElementProxyMixin, PolymerBase {
  DomIf.created() : super.created();

  void render() => jsElement.callMethod('render');
}
