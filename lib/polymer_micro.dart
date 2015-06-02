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
export 'src/common/polymer_element.dart';
export 'src/common/js_object_model.dart';
export 'src/common/property.dart';
import 'src/micro/properties.dart';
export 'src/micro/properties.dart';
export 'init.dart' show initPolymer;

class PolymerMicroElement extends HtmlElement with PolymerJsProxy {
  PolymerMicroElement.created([bool callCreated = true]) : super.created() {
    if (callCreated) polymerCreated();
  }

  void attached() => polymerAttached();

  void detached() => polymerDetached();

  void attributeChanged(String name, _, __) =>
      polymerAttributeChanged(name);


//  void set(String path, value) => jsThis.callMethod('set', [path, value]);
//  void notifyPath(String path, value) =>
//      jsThis.callMethod('notifyPath', [path, value]);
}
