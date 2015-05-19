// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@HtmlImport('package:polymer_interop/polymer_micro.html')
library polymer;

import 'dart:html';

import 'package:web_components/web_components.dart' show HtmlImport;
import 'src/micro/attributes.dart';
export 'src/micro/attributes.dart';
import 'src/micro/properties.dart';
export 'src/micro/properties.dart';

class PolymerMicroElement extends HtmlElement with Attributes, Properties {
  PolymerMicroElement.created() : super.created();

  polymerCreated() {
    installHostAttributes();
  }
}
