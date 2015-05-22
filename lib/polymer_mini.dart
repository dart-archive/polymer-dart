// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('package:polymer_interop/polymer_mini.html')
@HtmlImport('src/js/polymer_base_dart.html')
library polymer.lib.polymer_micro;

import 'dart:html';

import 'package:web_components/web_components.dart' show HtmlImport;
import 'polymer_micro.dart';
export 'polymer_micro.dart';
export 'init.dart' show initPolymer;

class PolymerMiniElement extends PolymerMicroElement {
  PolymerMiniElement.created() : super.created()
}
