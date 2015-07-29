// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.micro.lifecycle_callbacks_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer_micro.dart';

LifecycleTest element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('lifecycle-test');
  });

  test('created', () {
    expect(element.createdCalled, true);
  });

  test('attached', () {
    expect(element.attachedCalled, isFalse);
    document.body.append(element);
    expect(element.attachedCalled, isTrue);
  });

  test('detached', () {
    expect(element.detachedCalled, isFalse);
    document.body.append(element);
    element.remove();
    expect(element.detachedCalled, isTrue);
  });

  test('attributeChanged', () {
    expect(element.lastAttributeChangedArgs, isNull);
    element.attributes['foo'] = 'bar';
    expect(element.lastAttributeChangedArgs, ['foo', null, 'bar']);
    element.attributes['foo'] = 'baz';
    expect(element.lastAttributeChangedArgs, ['foo', 'bar', 'baz']);

    // Doesn't get called if the attribute didn't change.
    element.lastAttributeChangedArgs = null;
    element.attributes['foo'] = 'baz';
    expect(element.lastAttributeChangedArgs, isNull);
  });
}

@jsProxyReflectable
@PolymerRegister('lifecycle-test')
class LifecycleTest extends PolymerElement {
  bool createdCalled = false;
  bool attachedCalled = false;
  bool detachedCalled = false;
  List lastAttributeChangedArgs;

  LifecycleTest.created() : super.created() {
    createdCalled = true;
  }

  attached() {
    attachedCalled = true;
  }

  detached() {
    detachedCalled = true;
  }

  attributeChanged(String name, String oldValue, String newValue) {
    lastAttributeChangedArgs = [name, oldValue, newValue];
  }
}
