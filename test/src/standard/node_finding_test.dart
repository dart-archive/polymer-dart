// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.standard.node_finding_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;

TestElement element;

main() async {
  useHtmlConfiguration();
  smoke.useMirrors();
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('can find nodes by id with \$', () {
    expect(element.$['a'].id, 'a');
    expect(element.$['b'].id, 'b');
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  TestElement.created() : super.created();
}
