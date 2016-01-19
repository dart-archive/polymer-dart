// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.mini.bottom_up_ready_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer_mini.dart';

main() async {
  await initPolymer();

  test('Ready is called bottom-up', () {
    ParentElement parent = document.createElement('parent-element');
    ChildElement child = parent.querySelector('#child');
    GrandchildElement grandchild = child.querySelector('#grandchild');
    expect(parent.readyOrder, greaterThan(child.readyOrder));
    expect(child.readyOrder, greaterThan(grandchild.readyOrder));
  });
}

@behavior
class ReadyRecorder {
  static int _readiesSeen = 0;
  int readyOrder;

  static ready(ReadyRecorder instance) {
    instance.readyOrder = _readiesSeen++;
  }
}

@PolymerRegister('parent-element')
class ParentElement extends PolymerElement with ReadyRecorder {
  ParentElement.created() : super.created();
}

@PolymerRegister('child-element')
class ChildElement extends PolymerElement with ReadyRecorder {
  ChildElement.created() : super.created();
}

@PolymerRegister('grandchild-element')
class GrandchildElement extends PolymerElement with ReadyRecorder {
  GrandchildElement.created() : super.created();
}
