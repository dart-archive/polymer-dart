// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library polymer.test.property_change_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'common.dart';

// Dart note: this is a tad different from the JS code. We don't support putting
// expandos on Dart objects and then observing them. On the other hand, we want
// to make sure that superclass observers are correctly detected.

final _zonk = new Completer();
final _bar = new Completer();

@reflectable
class XBase extends PolymerElement {
  @observable String zonk = '';

  XBase.created() : super.created();

  zonkChanged() {
    _zonk.complete();
  }
}

@CustomTag('x-test')
class XTest extends XBase {
  @observable String bar = '';

  XTest.created() : super.created();

  ready() {
    bar = 'bar';
    new Future(() {
      zonk = 'zonk';
    });
  }

  barChanged() {
    _bar.complete();
  }
}

main() => initPolymer().then((zone) => zone.run(() {
  XTest testEl;

  setUp(() {
    testEl = querySelector('x-test');
    return Polymer.onReady;
  });

  test('bar change detected', () async {
    await _bar.future;
    expect(testEl.bar, 'bar', reason: 'change in ready calls *Changed');
  });
  test('zonk change detected', () async {
    await _zonk.future;
    expect(testEl.zonk, 'zonk', reason: 'change calls *Changed on superclass');
  });
}));
