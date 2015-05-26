// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';

import '../micro/properties.dart';

JsObject get _polymerBase => context['Polymer']['Base'];
JsObject get _polymerDartBasePrototype =>
    context['Polymer']['Dart']['Base']['prototype'];

final _customJsConstructorsByType = <Type, JsFunction>{};

/// Basic api for re-using the polymer js prototypes.
abstract class PolymerJsProxy {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) {
      _jsThis = new JsObject(_customJsConstructorsByType[this.runtimeType]);
      _jsThis['__proxy__'] = new JsObject.fromBrowserObject(this);
    }
    return _jsThis;
  }
}

/// Creates a [JsFunction] constructor and prototype for a dart [Type].
void createJsConstructorFor(Type type, Map<String, dynamic> hostAttributes) {
  var constructor = new JsFunction.withThis((_) {});
  var prototype = context['Object'].callMethod(
      'create', [_polymerDartBasePrototype]);
  addPropertyProxies(type, prototype);
  _polymerBase.callMethod(
      'extend', [
        prototype,
        new JsObject.jsify({
          'hostAttributes': hostAttributes,
          'getPropertyInfo':
              (property) => getPropertyInfoForType(type, property),
        }),
      ]);

  constructor['prototype'] = prototype;
  _customJsConstructorsByType[type] = constructor;
}
