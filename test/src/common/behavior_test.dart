// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.js_proxy_test;

import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';
import 'package:web_components/web_components.dart';

main() async {
  await initPolymer();
  MyElement el;

  group('lifecycle methods', () {
    setUp(() {
      el = new MyElement();
    });

    test('created', () {
      expect(el.dartInvocations['created'], [
        [el]
      ]);
      expect(el.jsElement['jsInvocations']['created'], [
        [el]
      ]);
      expect(el.dartInvocations['attached'], isEmpty);
      expect(el.dartInvocations['detached'], isEmpty);
      expect(el.dartInvocations['attributeChanged'], isEmpty);
    });

    test('attached', () {
      document.body.append(el);
      expect(el.dartInvocations['attached'], [
        [el]
      ]);
      expect(el.jsElement['jsInvocations']['attached'], [
        [el]
      ]);
      expect(el.dartInvocations['detached'], isEmpty);
      expect(el.dartInvocations['attributeChanged'], isEmpty);
    });

    test('detached', () {
      document.body.append(el);
      el.remove();
      expect(el.dartInvocations['detached'], [
        [el]
      ]);
      expect(el.jsElement['jsInvocations']['detached'], [
        [el]
      ]);
      expect(el.dartInvocations['attributeChanged'], isEmpty);
    });

    test('attributeChanged', () {
      el.attributes['foo'] = 'bar';
      expect(el.dartInvocations['attributeChanged'], [
        [el, 'foo', null, 'bar']
      ]);
      expect(el.jsElement['jsInvocations']['attributeChanged'], [
        [el, 'foo', null, 'bar']
      ]);
    });
  });
}

@BehaviorProxy(const ['JsBehavior'])
abstract class JsBehavior implements CustomElementProxyMixin {
  JsArray get jsInvocations => jsElement['jsInvocations'];
}

@Behavior()
class DartBehavior {
  Map<String, List<List>> dartInvocations = {
    'created': [],
    'attached': [],
    'detached': [],
    'attributeChanged': []
  };

  static created(DartBehavior thisArg) {
    thisArg.dartInvocations['created'].add([thisArg]);
  }

  static attached(DartBehavior thisArg) {
    thisArg.dartInvocations['attached'].add([thisArg]);
  }

  static detached(DartBehavior thisArg) {
    thisArg.dartInvocations['detached'].add([thisArg]);
  }

  static attributeChanged(DartBehavior thisArg, String name, type, value) {
    thisArg.dartInvocations['attributeChanged']
        .add([thisArg, name, type, value]);
  }
}

@jsProxyReflectable
@PolymerRegister('my-element')
class MyElement extends PolymerElement with JsBehavior, DartBehavior {
  MyElement.created() : super.created();

  factory MyElement() => document.createElement('my-element');
}
