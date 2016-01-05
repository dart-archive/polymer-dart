// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library polymer.test.build.static_clean_test;

import 'package:polymer/builder.dart';
import 'package:test/test.dart';

_unused() => build;

void main() {
  // Check that builder.dart is statically clean. Nothing to do.
  test('no errors', () {});
}
