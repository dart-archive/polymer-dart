// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.js_proxy_test;

import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';
import 'package:web_components/web_components.dart';
import '../../common.dart';

main() async {
  await initPolymer();
  MyElement el;

  group('behaviors', () {
    setUp(() {
      el = new MyElement();
    });

    group('lifecycle methods', () {
      _testCreated(invocations) {
        expect(invocations['created'], [
          [el]
        ]);
        expect(invocations['attached'], isEmpty);
        expect(invocations['detached'], isEmpty);
        expect(invocations['attributeChanged'], isEmpty);
      }

      test('JS created', () {
        _testCreated(el.jsInvocations);
      });

      test('Dart created', () {
        _testCreated(el.dartInvocations);
      });

      _testAttached(invocations) {
        document.body.append(el);
        expect(invocations['attached'], [
          [el]
        ]);
        expect(invocations['detached'], isEmpty);
        expect(invocations['attributeChanged'], isEmpty);
      }

      test('JS attached', () {
        _testAttached(el.jsInvocations);
      });

      test('Dart attached', () {
        _testAttached(el.dartInvocations);
      });

      _testDetached(invocations) {
        document.body.append(el);
        el.remove();
        expect(invocations['detached'], [
          [el]
        ]);
        expect(invocations['attributeChanged'], isEmpty);
      }

      test('JS detached', () {
        _testDetached(el.jsInvocations);
      });

      test('Dart detached', () {
        _testDetached(el.dartInvocations);
      });

      _testAttributeChanged(invocations) {
        el.attributes['foo'] = 'bar';
        expect(invocations['attributeChanged'], [
          [el, 'foo', null, 'bar']
        ]);
      }

      test('JS attributeChanged', () {
        _testAttributeChanged(el.jsInvocations);
      });

      test('Dart attributeChanged', () {
        _testAttributeChanged(el.dartInvocations);
      });
    });

    group('properties', () {
      test('JS behaviors', () {
        el.jsBehaviorString = 'jsValue';
        expect(el.jsBehaviorString, 'jsValue');
        expect(el.$['jsBehaviorString'].text, 'jsValue');
      });

      test('Dart behaviors', () {
        // TODO(jakemac): https://github.com/dart-lang/polymer-dart/issues/527
        el.set('dartBehaviorString', 'dartValue');
        expect(el.dartBehaviorString, 'dartValue');
        expect(el.$['dartBehaviorString'].text, 'dartValue');
      });
    });

    group('observers', () {
      test('JS property.observe', () {
        el.jsBehaviorString = 'jsValue';
        expect(el.jsInvocations['jsBehaviorStringChanged'], [
          ['jsValue', null]
        ]);
      });

      test('Dart property.observe', () {
        el.set('dartBehaviorString', 'dartValue');
        // TODO(jakemac): Remove inital `[null, null]` call once we fix
        // https://github.com/dart-lang/polymer-dart/issues/558
        expect(el.dartInvocations['dartBehaviorStringChanged'], [
          [null, null],
          ['dartValue', null]
        ]);
      });

      test('Js observers', () {
        el.jsBehaviorNum = 1;
        expect(el.jsInvocations['jsBehaviorNumChanged'], [
          [1]
        ]);
      });

      test('Dart @Observe', () {
        el.set('dartBehaviorNum', 1);
        // TODO(jakemac): Remove inital `null` call once we fix
        // https://github.com/dart-lang/polymer-dart/issues/558
        expect(el.dartInvocations['dartBehaviorNumChanged'], [
          [null],
          [1]
        ]);
      });
    });

    group('listeners', () {
      test('JS listeners', () {
        var e = new CustomEvent('js-behavior-event', detail: 'js Detail');
        el.dispatchEvent(e);
        expect(el.jsInvocations['onJsBehaviorEvent'], [
          [e, e.detail]
        ]);
      });

      test('Dart @Listen', () {
        var e = new CustomEvent('dart-behavior-event', detail: 'dart Detail');
        el.dispatchEvent(e);
        expect(el.dartInvocations['onDartBehaviorEvent'], [
          [e, e.detail]
        ]);
      });
    });
  });
}

@BehaviorProxy(const ['JsBehavior'])
abstract class JsBehavior implements CustomElementProxyMixin {
  JsObject get jsInvocations => jsElement['jsInvocations'];

  String get jsBehaviorString => jsElement['jsBehaviorString'];
  void set jsBehaviorString(String value) {
    jsElement['jsBehaviorString'] = value;
  }

  num get jsBehaviorNum => jsElement['jsBehaviorNum'];
  void set jsBehaviorNum(num value) {
    jsElement['jsBehaviorNum'] = value;
  }
}

@behavior
class DartBehavior {
  // Internal bookkeeping
  Map<String, List<List>> dartInvocations = {
    'created': [],
    'attached': [],
    'detached': [],
    'attributeChanged': [],
    'dartBehaviorStringChanged': [],
    'dartBehaviorNumChanged': [],
    'onDartBehaviorEvent': []
  };

  // Lifecycle Methods
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

  // Properties
  @Property(observer: 'dartBehaviorStringChanged')
  String dartBehaviorString;
  @property
  int dartBehaviorNum;

  @eventHandler
  void dartBehaviorStringChanged(String newValue, String oldValue) {
    dartInvocations['dartBehaviorStringChanged'].add([newValue, oldValue]);
  }

  // Observers
  @Observe('dartBehaviorNum')
  dartBehaviorNumChanged(dartBehaviorNum) {
    dartInvocations['dartBehaviorNumChanged'].add([dartBehaviorNum]);
  }

  // Listeners
  @Listen('dart-behavior-event')
  void onDartBehaviorEvent(e, [_]) {
    dartInvocations['onDartBehaviorEvent'].add([e, _]);
  }
}

@jsProxyReflectable
@PolymerRegister('my-element')
class MyElement extends PolymerElement with JsBehavior, DartBehavior {
  MyElement.created() : super.created();

  factory MyElement() => document.createElement('my-element');
}
