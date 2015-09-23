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
        expect(invocations['ready'], [
          [el]
        ]);
        expect(invocations['attached'], isEmpty);
        expect(invocations['detached'], isEmpty);
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
      }

      test('JS detached', () {
        _testDetached(el.jsInvocations);
      });

      test('Dart detached', () {
        _testDetached(el.dartInvocations);
      });

      _testAttributeChanged(invocations) {
        expect(invocations['attributeChanged'], [
          [el, 'js', null, 'hello'],
          [el, 'dart', null, 'hello'],
        ]);
        el.attributes['js'] = 'is widely used';
        el.attributes['dart'] = 'is the best';
        expect(invocations['attributeChanged'], [
          [el, 'js', null, 'hello'],
          [el, 'dart', null, 'hello'],
          [el, 'js', 'hello', 'is widely used'],
          [el, 'dart', 'hello', 'is the best'],
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
        expect(el.dartInvocations['dartBehaviorStringChanged'], [
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
        expect(el.dartInvocations['dartBehaviorNumChanged'], [
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
        var e = el.fire('dart-behavior-event', detail: 'dart Detail');
        var invocations = el.dartInvocations['onDartBehaviorEvent'];
        expect(invocations.length, 1);
        expect((invocations[0][0] as CustomEventWrapper).original, e.original);
        expect(invocations[0][1], e.detail);
      });
    });

    group('host attributes', () {
      test('get assigned', () {
        expect(el.attributes['dart'], 'hello');
        expect(el.attributes['js'], 'hello');
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
    'ready': [],
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

  static ready(DartBehavior thisArg) {
    thisArg.dartInvocations['ready'].add([thisArg]);
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

  // Host Attributes
  static const Map<String, String> hostAttributes = const {'dart': 'hello'};
}

@PolymerRegister('my-element')
class MyElement extends PolymerElement with JsBehavior, DartBehavior {
  MyElement.created() : super.created();

  factory MyElement() => document.createElement('my-element');
}
