// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.attributes;

import 'dart:html';
import 'dart:js';
import 'properties.dart';
import '../common/polymer_js_proxy.dart';

final _polymerBase = context['Polymer']['Base'];

abstract class Attributes implements PolymerProxy, Properties {
  void installHostAttributes(Map<String, dynamic> hostAttributes) =>
      (jsThis['_installHostAttributes'] as JsFunction).apply(
          [new JsObject.jsify(hostAttributes)], thisArg: jsThis);

  void marshalAttributes() =>
      (jsThis['_marshalAttributes'] as JsFunction).apply([], thisArg: jsThis);
}
