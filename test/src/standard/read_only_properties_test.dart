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

  test('Properties withough setters are read only', () {
    expect(element.jsElement['properties']['name']['readOnly'], isTrue);
    expect(element.$['name'].text, 'Jack');

    expect(() => element.set('name', 'John'), throws);
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @property
  String get name => 'Jack';

  TestElement.created() : super.created();
}
