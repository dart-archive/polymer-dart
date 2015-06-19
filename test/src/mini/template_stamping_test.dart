// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.micro.template_stamping_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer_mini.dart';
import 'package:smoke/mirrors.dart' as smoke;

TestElement element;

main() async {
  useHtmlConfiguration();
  smoke.useMirrors();
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('templates can be stamped!', () {
    expect(element.children.length, 1);
    expect(element.children.first.text, 'test!');
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  TestElement.created() : super.created();
}
