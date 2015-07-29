// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.polymer_register_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

main() async {
  await initPolymer();

  test('regular elements', () {
    expect(querySelector('#testElement') is TestElement, isTrue);
  });

  test('extending builtin elements', () {
    expect(querySelector('#testInput') is TestInput, isTrue);
  });
}

@jsProxyReflectable
@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  TestElement.created() : super.created();
}

@jsProxyReflectable
@PolymerRegister('test-input', extendsTag: 'input')
class TestInput extends InputElement with PolymerMixin, JsProxy {
  TestInput.created() : super.created();
}
