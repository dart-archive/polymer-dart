// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('polymer_micro.html')
library polymer.lib.polymer_micro;

import 'dart:html';

import 'package:polymer_interop/polymer_interop.dart';
export 'package:polymer_interop/polymer_interop.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
export 'src/common/behavior.dart';
import 'src/common/polymer_mixin.dart';
export 'src/common/polymer_mixin.dart';
export 'src/common/polymer_register.dart';
export 'src/common/polymer_serialize.dart';
export 'src/common/js_proxy.dart';
export 'src/common/property.dart';
export 'init.dart' show initPolymer;

class PolymerElement extends HtmlElement with PolymerMixin, PolymerBase {
  PolymerElement.created() : super.created() {
    polymerCreated();
  }
}
