// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('polymer.html')
@HtmlImport('src/js/polymer_base_dart.html')
library polymer.lib.polymer;

import 'package:web_components/web_components.dart' show HtmlImport;
import 'polymer_mini.dart';
export 'polymer_mini.dart';

class PolymerStandardElement extends PolymerMiniElement {
  PolymerStandardElement.created() : super.created();
}
