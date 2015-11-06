// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:js';
import 'package:web_components/web_components.dart';
import 'js_proxy.dart';

/// Basic api for re-using the polymer js prototypes.
@jsProxyReflectable
abstract class PolymerMixin implements CustomElementProxyMixin {
  JsObject _proxy;

  JsObject get jsElement {
    if (_proxy == null) {
      _proxy = new JsObject.fromBrowserObject(this);
    }
    return _proxy;
  }

  void polymerCreated() {
    jsElement.callMethod('originalPolymerCreatedCallback');
  }
}
