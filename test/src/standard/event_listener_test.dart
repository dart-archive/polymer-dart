// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.event_listener_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;

TestElement element;

main() async {
  smoke.useMirrors();
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  test('listen to events with @Listen', () {
    expect(element.sawCustomEvent, isFalse);
    element.fire('custom-event');
    expect(element.sawCustomEvent, isTrue);
  });

  test('template based event listeners', () {
    expect(element.sawButtonEvent, isFalse);
    element.$['myButton'].click();
    expect(element.sawButtonEvent, isTrue);
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  bool sawCustomEvent = false;
  bool sawButtonEvent = false;

  TestElement.created() : super.created();

  @Listen('custom-event')
  void onCustomEvent() {
    sawCustomEvent = true;
  }

  @eventHandler
  void buttonClicked() {
    sawButtonEvent = true;
  }
}
