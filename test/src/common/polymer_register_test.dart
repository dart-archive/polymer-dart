// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.common.polymer_register_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() async {
  smoke.useMirrors();
  useHtmlConfiguration();
  await initPolymer();

  test('regular elements', () {
    expect(querySelector('#testElement') is TestElement, isTrue);
  });

  test('extending builtin elements', () {
    expect(querySelector('#testInput') is TestInput, isTrue);
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  TestElement.created() : super.created();
}

@PolymerRegister('test-input', extendsTag: 'input')
class TestInput extends InputElement with PolymerMixin, JsProxy {
  TestInput.created() : super.created();
}
