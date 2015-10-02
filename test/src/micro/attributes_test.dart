// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.micro.attributes_test;

import 'dart:html';
import 'dart:js';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

const attributesName = 'attributes-test';
const serializeAttributesName = 'serialize-attributes-test';

main() async {
  await initPolymer();

  _tests(attributesName);
  _tests(serializeAttributesName);
}

_tests(String elementName) {
  group(elementName, () {
    var element;

    setUp(() {
      element = querySelector(elementName);
    });

    test('attributes can be marshalled into properties', () {
      expect(element.myString, 'string');
      expect(element.myNum, 2);
      expect(element.myBool, true);
      expect(element.myMap, {'hello': 'world'});
      expect(element.myList, ['hello', 'world']);
      expect(element.myDateTime, new DateTime(1987, 07, 18));
    });

    test('hostAttributes are applied to the host', () {
      expect(element.attributes['host-string'], 'string');
      expect(element.attributes['host-num'], '2');
      expect(element.attributes['host-bool'], '');
      expect(element.attributes['host-map'], '{"hello":"world"}');
      expect(element.attributes['host-list'], '["hello","world"]');
      // TODO(jakemac): Shouldn't have to go through js interop here.
      expect(
          element.jsElement.callMethod('deserialize',
              [element.attributes['host-date-time'], context['Date']]),
          new DateTime(1987, 07, 18));
    });

    if (elementName == serializeAttributesName) {
      test('serialized attributes can be marshalled into properties', () {
        expect(element.myFoobar, Foobar.bar);
      });
      test('serialized hostAttributes are applied to the host', () {
        expect(element.attributes['host-foobar'], 'bar');
      });
    }
  });
}

@PolymerRegister(attributesName)
class AttributesTest extends PolymerElement {
  @property
  String myString;

  @property
  num myNum;

  @property
  bool myBool;

  @property
  Map myMap;

  @property
  List myList;

  @property
  DateTime myDateTime;

  static final Map<String, String> hostAttributes = {
    'host-string': 'string',
    'host-num': 2,
    'host-bool': true,
    'host-map': const {'hello': 'world'},
    'host-list': const ['hello', 'world'],
    'host-date-time': new DateTime(1987, 07, 18),
  };

  AttributesTest.created() : super.created();
}

enum Foobar { foo, bar }

@PolymerRegister(serializeAttributesName)
class SerializedAttributesTest extends PolymerElement with PolymerSerialize {
  @property
  String myString;

  @property
  num myNum;

  @property
  bool myBool;

  @property
  Map myMap;

  @property
  List myList;

  @property
  DateTime myDateTime;

  @property
  Foobar myFoobar = Foobar.bar;

  static final Map<String, String> hostAttributes = {
    'host-string': 'string',
    'host-num': 2,
    'host-bool': true,
    'host-map': const {'hello': 'world'},
    'host-list': const ['hello', 'world'],
    'host-date-time': new DateTime(1987, 07, 18),
    'host-foobar': Foobar.bar
  };

  SerializedAttributesTest.created() : super.created();

  String serialize(Object value) {
    return (value is Foobar)
        ? value.toString().split('.')[1]
        : super.serialize(value);
  }

  Object deserialize(String value, dynamic type) {
    if (type == Foobar) {
      return value == 'bar' ? Foobar.bar : Foobar.foo;
    } else {
      return super.deserialize(value, type);
    }
  }
}
