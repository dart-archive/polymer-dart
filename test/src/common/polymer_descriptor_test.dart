// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
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
    var annotation = const PolymerRegister('test-element', extendsTag: 'div');
    JsObject descriptor = createPolymerDescriptor(Test, annotation);

    expect(descriptor['is'], annotation.tagName);
    expect(descriptor['extends'], annotation.extendsTag);
    expect(descriptor['__isPolymerDart__'], true);
    expectEqual(descriptor['hostAttributes'], Test.hostAttributes);

    var properties = descriptor['properties'];
    expectProperty(properties['myString'], type: context['String']);
    expectProperty(properties['myInt'], type: context['Number'], notify: true);
    expectProperty(properties['myDouble'],
        type: context['Number'], observer: 'myDoubleChanged');
    expectProperty(properties['myNum'],
        type: context['Number'], reflectToAttribute: true);
    expectProperty(properties['myBool'], type: context['Boolean']);
    expectProperty(properties['myMap']);
    expectProperty(properties['myStringMap']);
    expectProperty(properties['myList'], type: context['Array']);
    expectProperty(properties['myStringList'], type: context['Array']);
    expectProperty(properties['myDateTime'], type: context['Date']);
    expectProperty(properties['computedNum'],
        type: context['Number'],
        computed: 'myNumsCombined(myInt, myDouble, myNum)');
    // From the dart behaviors!
    expectProperty(properties['behaviorOneProperty'], type: context['String']);
    expectProperty(properties['behaviorTwoProperty'], type: context['Number']);

    var observers = descriptor['observers'];
    expect(observers, contains('myStringChanged(myString)'));
    expect(observers, contains('myDoubleOrIntChanged(myDouble, myInt)'));
    // From the dart behaviors!
    expect(
        observers, contains('behaviorOnePropertyChanged(behaviorOneProperty)'));
    expect(
        observers, contains('behaviorTwoPropertyChanged(behaviorTwoProperty)'));

    var listeners = descriptor['listeners'];
    expect(listeners['tap'], 'onTap');
    expect(listeners['someId.tap'], 'onSomeIdTap');
    // From the dart behaviors!
    expect(listeners['someEventOne'], 'onSomeEventOne');
    expect(listeners['someEventTwo'], 'onSomeEventTwo');

    expect(descriptor['ready'] is JsFunction, isTrue);
    expect(descriptor['attached'] is JsFunction, isTrue);
    expect(descriptor['detached'] is JsFunction, isTrue);
    expect(descriptor['handleSomeEvent'] is JsFunction, isTrue);
    expect(descriptor['myDoubleChanged'] is JsFunction, isTrue);
    expect(descriptor['myNumsCombined'] is JsFunction, isTrue);
    // From the dart behaviors!
    expect(descriptor['behaviorOneExposedMethod'] is JsFunction, isTrue);
    expect(descriptor['behaviorTwoExposedMethod'] is JsFunction, isTrue);

    expect(descriptor['behaviors'], isNotNull);
    expect(descriptor['behaviors'].length, 5);
    expect(descriptor['behaviors'][0], context['Polymer']['Dart']['Behavior']);
    expect(descriptor['behaviors'][1], context['Foo']['JsBehaviorOne']);
    expect(descriptor['behaviors'][2], behavior.getBehavior(DartBehaviorOne));
    expect(descriptor['behaviors'][3], context['Foo']['JsBehaviorTwo']);
    expect(descriptor['behaviors'][4], behavior.getBehavior(DartBehaviorTwo));
    expect(descriptor['behaviors'][2], isNot(descriptor['behaviors'][3]));
  });
}

@BehaviorProxy(const ['Foo', 'JsBehaviorOne'])
class JsBehaviorOne {}

@BehaviorProxy(const ['Foo', 'JsBehaviorTwo'])
class JsBehaviorTwo {}

@behavior
class DartBehaviorOne {
  @property
  String behaviorOneProperty;

  @Observe('behaviorOneProperty')
  void behaviorOnePropertyChanged() {}

  @Listen('someEventOne')
  void onSomeEventOne() {}

  @eventHandler
  void behaviorOneExposedMethod() {}
}

@behavior
class DartBehaviorTwo {
  @property
  int behaviorTwoProperty;

  @Observe('behaviorTwoProperty')
  void behaviorTwoPropertyChanged() {}

  @Listen('someEventTwo')
  void onSomeEventTwo() {}

  @eventHandler
  void behaviorTwoExposedMethod() {}
}

class Test extends PolymerElement
    with JsBehaviorOne, DartBehaviorOne, JsBehaviorTwo, DartBehaviorTwo {
  Test.created() : super.created();

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

  static Map<String, String> hostAttributes = const {'foo': 'bar'};
}

void expectProperty(JsObject actual,
    {computed: null,
    defined: true,
    notify: false,
    observer: null,
    reflectToAttribute: false,
    type: null,
    value: isNotNull}) {
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
