//Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
//for details. All rights reserved. Use of this source code is governed by a
//BSD-style license that can be found in the LICENSE file.
library polymer_dart.test.common;

import 'dart:async';

Future wait(int milliseconds) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}
