// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.mini.template_stamping_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer_mini.dart';

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('templates can be stamped!', () {
    expect(element.children.length, 1);
    expect(element.children.first.text, 'test!');
  });
}

@jsProxyReflectable
@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  TestElement.created() : super.created();
}
