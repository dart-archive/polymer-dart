// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.dart.lib.case_map;

import 'dart:js';

final _CaseMap = context['Polymer']['CaseMap'];

String dashToCamelCase(String dash) =>
  (_CaseMap['dashToCamelCase'] as JsFunction).apply([dash]);

String camelToDashCase(String camel) =>
  (_CaseMap['camelToDashCase'] as JsFunction).apply([camel]);
