// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.attribute_binding_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('can bind to attributes directly using \$=', () {
    expect(element.$['myLink'].attributes['href'], element.url);
    element.set('url', 'http://wikipedia.com');
    expect(element.$['myLink'].attributes['href'], element.url);
  });
}

@jsProxyReflectable
@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @property
  String url = 'http://google.com';

  TestElement.created() : super.created();
}
