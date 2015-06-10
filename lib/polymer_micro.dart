// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('polymer_micro.html')
library polymer.lib.polymer_micro;

import 'dart:html';
import 'dart:js';

import 'package:web_components/web_components.dart' show HtmlImport;
export 'src/common/event_handler.dart';
import 'src/common/polymer_js_mixin.dart';
export 'src/common/polymer_js_mixin.dart';
export 'src/common/polymer_element.dart';
export 'src/common/js_object_model.dart';
import 'src/common/js_proxy.dart';
export 'src/common/js_proxy.dart';
export 'src/common/observe.dart';
export 'src/common/property.dart';
import 'src/micro/properties.dart';
export 'src/micro/properties.dart';
export 'init.dart' show initPolymer;

class PolymerMicroElement extends HtmlElement with PolymerJsMixin, JsProxy {
  PolymerMicroElement.created() : super.created() {
    polymerCreated();
  }
}
