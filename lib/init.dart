// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.init;

import 'dart:async';
import 'package:initialize/initialize.dart' show Initializer;
import 'package:web_components/web_components.dart';
import 'src/common/polymer_register.dart';

main() => initPolymer();

Future initPolymer() async {
  await initWebComponents(
      typeFilter: [
        HtmlImport, CustomElement, CustomElementProxy, PolymerRegister
      ],
      initAll: true);
}
