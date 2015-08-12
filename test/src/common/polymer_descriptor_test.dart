// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.polymer_descriptor_test;

import 'dart:js';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';
import 'package:polymer/src/common/polymer_descriptor.dart';

main() async {

  await initPolymer();

  test('can build polymer descriptor objects', () {
    var annotation = const PolymerRegister(
        'test-element',
        extendsTag: 'div',
        hostAttributes: const {
          'foo': 'bar',
        });
    JsObject descriptor = createPolymerDescriptor(Test, annotation);

    expect(descriptor['is'], annotation.tagName);
    expect(descriptor['extends'], annotation.extendsTag);
    expect(descriptor['__isPolymerDart__'], true);
    expectEqual(descriptor['hostAttributes'], annotation.hostAttributes);

    var properties = descriptor['properties'];
    expectProperty(properties['myString'], type: context['String']);
    expectProperty(properties['myInt'], type: context['Number'], notify: true);
    expectProperty(properties['myDouble'], type: context['Number'],
        observer: 'myDoubleChanged');
    expectProperty(properties['myNum'], type: context['Number'],
        reflectToAttribute: true);
    expectProperty(properties['myBool'], type: context['Boolean']);
    expectProperty(properties['myMap']);
    expectProperty(properties['myStringMap']);
    expectProperty(properties['myList'], type: context['Array']);
    expectProperty(properties['myStringList'], type: context['Array']);
    expectProperty(properties['myDateTime'], type: context['Date']);
    expectProperty(properties['computedNum'], type: context['Number'],
        computed: 'myNumsCombined(myInt, myDouble, myNum)');

    var observers = descriptor['observers'];
    expect(observers[0], 'myStringChanged(myString)');
    expect(observers[1], 'myDoubleOrIntChanged(myDouble, myInt)');

    var listeners = descriptor['listeners'];
    expect(listeners['tap'], 'onTap');
    expect(listeners['someId.tap'], 'onSomeIdTap');

    expect(descriptor['ready'] is JsFunction, isTrue);
    expect(descriptor['attached'] is JsFunction, isTrue);
    expect(descriptor['detached'] is JsFunction, isTrue);
    expect(descriptor['handleSomeEvent'] is JsFunction, isTrue);
    expect(descriptor['myDoubleChanged'] is JsFunction, isTrue);
    expect(descriptor['myNumsCombined'] is JsFunction, isTrue);

    expect(descriptor['behaviors'], isNotNull);
    expect(descriptor['behaviors'].length, 2);
    expect(descriptor['behaviors'][0], context['Foo']['BehaviorOne']);
    expect(descriptor['behaviors'][1], context['Foo']['BehaviorTwo']);
  });
}

@BehaviorProxy(const ['Foo', 'BehaviorOne'])
class BehaviorOne {}

@BehaviorProxy(const ['Foo', 'BehaviorTwo'])
class BehaviorTwo {}

@jsProxyReflectable
class Test extends Object with BehaviorOne, BehaviorTwo {
  @property
  String myString;
  @Property(notify: true)
  int myInt;
  @Property(observer: 'myDoubleChanged')
  double myDouble;
  @Property(reflectToAttribute: true)
  num myNum;
  @property
  bool myBool;
  @property
  Map myMap;
  @property
  Map<String, String> myStringMap;
  @property
  List myList;
  @property
  List<String> myStringList;
  @property
  DateTime myDateTime;
  @Property(computed: 'myNumsCombined(myInt, myDouble, myNum)')
  num computedNum;

  void ready() {}
  void attached() {}
  void detached() {}

  @Observe('myString')
  void myStringChanged() {}

  @Observe('myDouble, myInt')
  void myDoubleOrIntChanged() {}

  @Listen('tap')
  void onTap() {}

  @Listen('someId.tap')
  void onSomeIdTap() {}

  @eventHandler
  void handleSomeEvent() {}

  @eventHandler
  void myDoubleChanged() {}

  @eventHandler
  num myNumsCombined() {
    return myInt + myDouble + myNum;
  }
}

void expectProperty(JsObject actual, {
    computed: null, defined: true, notify: false, observer: null,
    reflectToAttribute: false, type: null, value: isNotNull}) {
  var expected = {
    'computed': computed,
    'defined': defined,
    'notify': notify,
    'observer': observer,
    'reflectToAttribute': reflectToAttribute,
    'type': (type == null) ? context['Object'] : type,
    'value': value,
  };
  expectEqual(actual, expected);
}

void expectEqual(JsObject actual, Map expected) {
  expect(actual, isNotNull);
  var keys = context['Object'].callMethod('keys', [actual]);
  for (var key in keys) {
    expect(actual[key], equals(expected[key]));
  }
}
