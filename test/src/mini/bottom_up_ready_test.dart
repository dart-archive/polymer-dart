// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.mini.bottom_up_ready_test;

import 'dart:async';
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

@PolymerRegister('parent-element')
class ParentElement extends ReadyRecordingElement {
  ParentElement.created() : super.created();
}

@PolymerRegister('child-element')
class ChildElement extends ReadyRecordingElement {
  ChildElement.created() : super.created();
}

@PolymerRegister('grandchild-element')
class GrandchildElement extends ReadyRecordingElement {
  GrandchildElement.created() : super.created();
}

class ReadyRecordingElement extends PolymerElement {
  static int _readiesSeen = 0;
  int readyOrder;

  ReadyRecordingElement.created() : super.created();

  ready() {
    readyOrder = _readiesSeen++;
  }
}
