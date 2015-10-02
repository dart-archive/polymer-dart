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

  test('Properties without setters are read only', () {
    expect(element.jsElement['properties']['name']['readOnly'], isTrue);
    expect(element.$['name'].text, 'Jack');

    expect(() => element.set('name', 'John'), throws);
  });

  test('Properties without setters can be notified of changes', () {
    element._name = 'John';
    expect(element.notifyPath('name', element._name), isNull);
    expect(element.$['name'].text, element._name);
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @property
  String get name => _name;
  String _name = 'Jack';

  TestElement.created() : super.created();
}
