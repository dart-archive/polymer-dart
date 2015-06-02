// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;
import 'property.dart';
import '../micro/properties.dart';

/// Basic api for re-using the polymer js prototypes.
abstract class PolymerJsMixin {
  JsObject _proxy;

  JsObject get jsElement {
    if (_proxy == null) {
//      print('setting up proxy for: $this');
      _proxy = new JsObject.fromBrowserObject(this);
      _proxy['__dartClass__'] = this;
      _proxy['__data__']['__dartClass__'] = this;
    }
    return _proxy;
  }

  void polymerCreated() {
    // Set up the proxy.
    jsElement.callMethod('originalPolymerCreatedCallback');
  }

  /// Sets a value on an attribute path, and notifies of changes.
  void set(String path, value) =>
    jsElement.callMethod('set', [path, _jsValue(value)]);

  /// Notify of a change to a property path.
  void notifyPath(String path, value) =>
    jsElement.callMethod('notifyPath', [path, _jsValue(value)]);

  // TODO(jakemac): investigate wrapping this object in something that
  // implements map, see
  // https://chromiumcodereview.appspot.com/23291005/patch/25001/26002 for an
  // example of this.
  JsObject get $ => jsElement[r'$'];

  /// The shadow or shady root, depending on which system is in use.
  DocumentFragment get root => jsElement['root'];

  dynamic _jsValue(value) =>
      (value is Iterable || value is Map) ? new JsObject.jsify(value) : value;
}
