// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.computed_properties_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('computed properties', () {
    expect(element.computedProperty, 2);
    expect(element.$['computedProperty'].text, '2');

    element.set('first', 2);
    expect(element.computedProperty, 3);
    expect(element.$['computedProperty'].text, '3');

    element.set('second', 4);
    expect(element.computedProperty, 6);
    expect(element.$['computedProperty'].text, '6');
  });
}

@jsProxyReflectable
@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @Property(computed: 'addProperties(first, second)')
  int computedProperty;

  @property
  int first = 1;

  @property
  int second = 1;

  TestElement.created() : super.created();

  @eventHandler
  int addProperties([_, __]) => first + second;
}
