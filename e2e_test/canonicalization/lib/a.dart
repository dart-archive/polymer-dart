// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canonicalization.a;

import 'package:polymer/polymer.dart';
import 'package:canonicalization/c.dart';
import 'd.dart';

int a = 0;
@initMethod initA() {
  a++;
  c++;
  d++;
}
