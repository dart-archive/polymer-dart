// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.init;

import 'dart:async';
import 'dart:js' show context;
import 'package:web_components/web_components.dart';
import 'src/common/polymer_element.dart';

main() => initPolymer();

Future initPolymer() async {
  await initWebComponents(typeFilter: [HtmlImport], initAll: false);
//  context['Polymer']['Dart']['Base'].callMethod('__setup__', []);
  await initWebComponents(typeFilter: [PolymerElement], initAll: false);
  await initWebComponents();
}
