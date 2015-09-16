// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.mini.default_values_test;

import 'dart:html';
import 'package:test/test.dart';
// TODO(jakemac): Why doesn't this work with polymer_mini.dart?
import 'package:polymer/polymer.dart';

SimpleElement element;

main() async {
  await initPolymer();

  test('Initializers are passed as default values to js', () {
    element = document.createElement('simple-element');

    expect(element.message, 'hello world!');
    expect(element.jsProxy['message'], 'hello world!');
    expect(element.text, contains('hello world!'));
  });
}

@PolymerRegister('simple-element')
class SimpleElement extends PolymerElement {
  @property
  String message = 'hello world!';

  SimpleElement.created() : super.created();
}
