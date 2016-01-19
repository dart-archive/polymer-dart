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
    expect(descriptor['beforeRegister'] is JsFunction, isTrue);
    expect(descriptor['registered'] is JsFunction, isTrue);

    // Element properties
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

    // Reflectable fields and methods
    expect(descriptor['handleSomeEvent'] is JsFunction, isTrue);
    expect(descriptor['myDoubleChanged'] is JsFunction, isTrue);
    expect(descriptor['myNumsCombined'] is JsFunction, isTrue);
    expect(
        descriptor.callMethod('hasOwnProperty', ['myReflectableInt']), isTrue);
    expect(descriptor['myReflectableStaticInt'], isNull);
    expect(descriptor.callMethod('getMyReflectableStaticInt'), isNull);
    Test.myReflectableStaticInt = 1;
    expect(descriptor['myReflectableStaticInt'], 1);
    expect(descriptor.callMethod('getMyReflectableStaticInt'), 1);
    descriptor['myReflectableStaticInt'] = 2;
    expect(Test.myReflectableStaticInt, 2);
    expect(descriptor.callMethod('getMyReflectableStaticInt'), 2);

    // Observers
    var observers = descriptor['observers'];
    expect(observers, contains('myStringChanged(myString)'));
    expect(observers, contains('myDoubleOrIntChanged(myDouble, myInt)'));

    // Listeners
    var listeners = descriptor['listeners'];
    expect(listeners['tap'], 'onTap');
    expect(listeners['someId.tap'], 'onSomeIdTap');

    // Lifecycle methods
    expect(descriptor['ready'] is JsFunction, isTrue);
    expect(descriptor['attached'] is JsFunction, isTrue);
    expect(descriptor['detached'] is JsFunction, isTrue);

    // Behaviors!
    var behaviors = descriptor['behaviors'];
    expect(behaviors, isNotNull);
    expect(descriptor['behaviors'].length, 5);

    expect(behaviors[0], context['Polymer']['Dart']['InteropBehavior']);

    expect(behaviors[1], context['Foo']['JsBehaviorOne']);

    expect(behaviors[2], behavior.getBehavior(DartBehaviorOne));
    expect(behaviors[2]['listeners']['someEventOne'], 'onSomeEventOne');
    expectProperty(behaviors[2]['properties']['behaviorOneProperty'],
        type: context['String']);
    expect(behaviors[2]['observers'],
        contains('behaviorOnePropertyChanged(behaviorOneProperty)'));
    expect(behaviors[2]['behaviorOneExposedMethod'] is JsFunction, isTrue);
    expect(behaviors[2]['beforeRegister'] is JsFunction, isTrue);
    expect(behaviors[2]['registered'] is JsFunction, isTrue);

    expect(behaviors[3], context['Foo']['JsBehaviorTwo']);

    expect(behaviors[4], behavior.getBehavior(DartBehaviorTwo));
    expect(behaviors[4]['beforeRegister'] is JsFunction, isTrue);
    expect(behaviors[4]['registered'] is JsFunction, isTrue);
    expect(behaviors[4], isNot(descriptor['behaviors'][3]));
    expect(behaviors[4]['listeners']['someEventTwo'], 'onSomeEventTwo');
    expectProperty(behaviors[4]['properties']['behaviorTwoProperty'],
        type: context['Number']);
    expect(behaviors[4]['observers'],
        contains('behaviorTwoPropertyChanged(behaviorTwoProperty)'));
    expect(behaviors[4]['behaviorTwoExposedMethod'] is JsFunction, isTrue);
  });

  test('instance methods named `registered` are not allowed', () {
    var annotation = const PolymerRegister('bad-registered', extendsTag: 'div');
    expect(() {
      createPolymerDescriptor(BadRegistered, annotation);
    }, throws);
  });

  test('instance methods named `beforeRegister` are not allowed', () {
    var annotation =
        const PolymerRegister('bad-before-register', extendsTag: 'div');
    expect(() {
      createPolymerDescriptor(BadRegistered, annotation);
    }, throws);
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

  @reflectable
  void behaviorOneExposedMethod() {}

  static void registered(JsObject proto) {}

  static void beforeRegister(JsObject proto) {}
}

@behavior
class DartBehaviorTwo {
  @property
  int behaviorTwoProperty;

  @Observe('behaviorTwoProperty')
  void behaviorTwoPropertyChanged() {}

  @Listen('someEventTwo')
  void onSomeEventTwo() {}

  @reflectable
  void behaviorTwoExposedMethod() {}

  static void registered(JsObject proto) {}

  static void beforeRegister(JsObject proto) {}
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

  @reflectable
  int myReflectableInt;
  @reflectable
  static int myReflectableStaticInt;

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

  @reflectable
  void handleSomeEvent() {}

  @reflectable
  void myDoubleChanged() {}

  @reflectable
  num myNumsCombined() {
    return myInt + myDouble + myNum;
  }

  @reflectable
  static int getMyReflectableStaticInt() => Test.myReflectableStaticInt;

  static Map<String, String> hostAttributes = const {'foo': 'bar'};

  static void registered(JsObject proto) {}

  static void beforeRegister(JsObject proto) {}
}

// Class containing an instance method named `registered`.
class BadRegistered extends PolymerElement {
  BadRegistered.created() : super.created();

  @reflectable
  registered() {}
}

// Class containing an instance method named `beforeRegister`.
class BadBeforeRegister extends PolymerElement {
  BadBeforeRegister.created() : super.created();

  @reflectable
  beforeRegister() {}
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
