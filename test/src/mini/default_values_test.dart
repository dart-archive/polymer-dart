// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.mini.default_values_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
// TODO(jakemac): Why doesn't this work with polymer_mini.dart?
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;

SimpleElement element;

main() async {
  useHtmlConfiguration();
  smoke.useMirrors();
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
