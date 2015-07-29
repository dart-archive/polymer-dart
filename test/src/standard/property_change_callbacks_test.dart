// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.property_change_callbacks_test.dart;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('@Property observer changes', () {
    expect(element.fooChangedCount, 1);
    element.set('foo', 1);
    expect(element.fooChangedCount, 2);
    element.set('foo', 0);
    expect(element.fooChangedCount, 3);

    // Shouldn't call again if the value didn't actually change.
    element.set('foo', 0);
    expect(element.fooChangedCount, 3);
  });

  test('@Observe single property change', () {
    expect(element.barChangedCount, 1);
    element.set('bar', 1);
    expect(element.barChangedCount, 2);
    element.set('bar', 2);
    expect(element.barChangedCount, 3);

    // Shouldn't call again if the value didn't actually change.
    element.set('bar', 2);
    expect(element.barChangedCount, 3);
  });

  test('@Observe multi property change', () {
    expect(element.fooOrBarChangedCount, 1);
    element.set('bar', 1);
    expect(element.fooOrBarChangedCount, 2);
    element.set('foo', 1);
    expect(element.fooOrBarChangedCount, 3);

    // Shouldn't call again if the value didn't actually change.
    element.set('bar', 1);
    element.set('foo', 1);
    expect(element.fooOrBarChangedCount, 3);
  });
}

@jsProxyReflectable
@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @Property(observer: 'fooChanged')
  int foo = 0;
  int fooChangedCount = 0;

  @property
  int bar = 0;
  int barChangedCount = 0;

  int fooOrBarChangedCount = 0;

  TestElement.created() : super.created();

  @eventHandler
  void fooChanged([_, __]) {
    fooChangedCount++;
  }

  @Observe('bar')
  void barChanged([_, __]) {
    barChangedCount++;
  }

  @Observe('foo, bar')
  void fooOrBarChanged([_, __]) {
    fooOrBarChangedCount++;
  }
}
