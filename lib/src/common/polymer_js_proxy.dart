// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';

import '../micro/properties.dart';

final JsObject _polymerDart = context['Polymer']['Dart'];
final JsObject _polymerDartBasePrototype = _polymerDart['Base']['prototype'];

final _customJsConstructorsByType = <Type, JsFunction>{};

/// Basic api for re-using the polymer js prototypes.
abstract class PolymerJsProxy {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) {
      _jsThis = new JsObject(_customJsConstructorsByType[this.runtimeType]);
      _jsThis['__proxy__'] = _jsThis['__data__']['__proxy__'] =
          new JsObject.fromBrowserObject(this);
    }
    return _jsThis;
  }

  void set(String path, value) => jsThis.callMethod('set', [path, value]);
}

/// Creates a [JsFunction] constructor and prototype for a dart [Type].
JsFunction createJsConstructorFor(
    Type type, String tagName, Map<String, dynamic> hostAttributes) {
  JsFunction constructor = _polymerDart.callMethod('functionFactory', []);
  JsObject prototype = context['Object'].callMethod(
      'create', [_polymerDartBasePrototype]);
//  setupProperties(type, prototype);
  prototype['hostAttributes'] = new JsObject.jsify(hostAttributes);
  prototype['is'] = tagName;

  constructor['prototype'] = prototype;
  _customJsConstructorsByType[type] = constructor;
  return constructor;
}
