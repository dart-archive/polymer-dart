// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.active_element_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';
import "dart:async";

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('active element', () async {
    element.focus();
    element.inp.focus();

    await new Future.delayed(new Duration(milliseconds:200));

    expect(new PolymerDom(element).activeElement,isNull);
    expect(new PolymerDom(element.root).activeElement,isNull);
  
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {

  InputElement get inp => $["inp"];

  TestElement.created() : super.created();
}
