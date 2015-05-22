// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';

import '../micro/attributes.dart';
import '../micro/properties.dart';

final JsFunction _polymerBaseConstructor = context['Polymer']['Dart']['Base'];

// Basic api for polymer js proxies. Will add things as needed.
abstract class PolymerJsProxy implements Properties {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) {
      _jsThis = new JsObject(_polymerBaseConstructor);
      _jsThis['__proxy__'] = new JsObject.fromBrowserObject(this);

      // Properties proxies
      _jsThis['getPropertyInfo'] = (property) =>
          PropertyInfo.toJsObject(getPropertyInfo(property));
    }
    return _jsThis;
  }
}
