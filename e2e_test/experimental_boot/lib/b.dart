// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library experimental_boot.b;

import 'package:polymer/polymer.dart';
import 'package:experimental_boot/c.dart';
import 'd.dart';

int b = 0;
@initMethod initB() {
  b++;
  c++;
  d++;
}
