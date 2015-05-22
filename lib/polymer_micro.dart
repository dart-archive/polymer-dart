// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('package:polymer_interop/polymer_micro.html')
@HtmlImport('src/js/polymer_base_dart.html')
library polymer.lib.polymer_micro;

import 'dart:html';
import 'dart:js';

import 'package:web_components/web_components.dart' show HtmlImport;
import 'src/common/polymer_js_proxy.dart';
export 'src/common/polymer_js_proxy.dart';
import 'src/micro/attributes.dart';
export 'src/micro/attributes.dart';
import 'src/micro/properties.dart';
export 'src/micro/properties.dart';
export 'init.dart' show initPolymer;

class PolymerMicroElement extends HtmlElement with PolymerJsProxy, Attributes, Properties {
  PolymerMicroElement.created() : super.created();

  void polymerCreated() {
    jsThis['hostAttributes'] = new JsObject.jsify(hostAttributes);
    jsThis.callMethod('createdCallback');
  }

  void attached() => jsThis.callMethod('attachedCallback');

  void detached() => jsThis.callMethod('detachedCallback');

  void attributeChanged(String name, _, __) =>
      jsThis.callMethod('attributeChangedCallback', [name]);
}
