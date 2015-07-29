// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.mini.dom_distribution_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer_mini.dart';

PolymerElement element;

main() async {
  await initPolymer();

  test('Simple', () {
    element = document.querySelector('simple-element');
    var div = element.querySelector('.content #hello');
    expect(div, isNotNull);
    expect(div.text, 'hello!');
  });

  test('Selector', () {
    element = document.querySelector('select-element');
    var div = element.querySelector('.content #invisible');
    expect(div, isNull);

    div = element.querySelector('.content #hello');
    expect(div, isNotNull);
    expect(div.text, 'hello!');

    expect(element.querySelector('#invisible'), isNull);
    expect(document.querySelector('#invisible'), isNull);
  });
}

@jsProxyReflectable
@PolymerRegister('simple-element')
class SimpleElement extends PolymerElement {
  SimpleElement.created() : super.created();
}

@jsProxyReflectable
@PolymerRegister('select-element')
class SelectElement extends PolymerElement {
  SelectElement.created() : super.created();
}
