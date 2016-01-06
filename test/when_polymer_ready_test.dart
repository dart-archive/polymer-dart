// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library polymer.test.when_polymer_ready_test;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';
import 'common.dart';

final Completer done = new Completer();

@CustomTag('x-a')
class XA extends PolymerElement {
  XA.created() : super.created();
}

main() {
  test('whenPolymerReady functions get called when polymer is ready', () {
    expect(querySelector('x-a') is XA, isFalse);
    initPolymer();
    return done.future;
  });
}

@whenPolymerReady
void whenReady() {
  expect(querySelector('x-a') is XA, isTrue);
  done.complete();
}
