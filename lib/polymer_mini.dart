// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('polymer_mini.html')
library polymer.lib.polymer_mini;

import 'package:polymer_interop/polymer_interop.dart' as polymer_interop;
export 'package:polymer_interop/polymer_interop.dart' show PolymerDom;
import 'package:web_components/web_components.dart' show HtmlImport;
import 'polymer_micro.dart';
export 'polymer_micro.dart';

class Polymer extends polymer_interop.Polymer {
  @override
  static polymer_interop.PolymerDom dom(node) {
    return new polymer_interop.PolymerDom(node);
  }
}

class PolymerMiniElement extends PolymerMicroElement {
  PolymerMiniElement.created() : super.created();
}
