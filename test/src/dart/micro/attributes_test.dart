// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.dart.micro.attributes_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:initialize/initialize.dart';
import 'package:polymer/polymer_micro.dart';
export 'package:web_components/init.dart';

AttributesTest element;

@initMethod
ready() {
   setUp(() {
     element = querySelector('attributes-test');
   });

  test('attributes can be marshalled into properties', () {
    expect(element.myString, 'string');
    expect(element.myInt, 1);
    expect(element.myDouble, 1.0);
    expect(element.myNum, 2);
    expect(element.myBool, true);
    expect(element.myMap, {'hello': 'world'});
    expect(element.myList, ['hello', 'world']);
    expect(element.myDateTime, new DateTime(1987, 07, 18));
  });

  test('hostAttributes are applied to the host', () {
    expect(element.attributes['host-string'], 'string');
    expect(element.attributes['host-int'], '1');
    expect(element.attributes['host-double'], '1.0');
    expect(element.attributes['host-num'], '2');
    expect(element.attributes['host-bool'], '');
    expect(element.attributes['host-map'], '{"hello":"world"}');
    expect(element.attributes['host-list'], '["hello","world"]');
    expect(element.attributes['host-date-time'],
        new DateTime(1987, 07, 18).toString());
  });
}

@CustomElement('attributes-test')
class AttributesTest extends HtmlElement with Attributes, Properties {
  String myString;
  int myInt;
  double myDouble;
  num myNum;
  bool myBool;
  Map myMap;
  List myList;
  DateTime myDateTime;


  AttributesTest.created() : super.created() {
    if (hostAttributes == null) hostAttributes = {};
    hostAttributes.addAll({
      'host-string': 'string',
      'host-int': 1,
      'host-double': 1.0,
      'host-num': 2,
      'host-bool': true,
      'host-map': {'hello': 'world'},
      'host-list': ['hello', 'world'],
      'host-date-time': new DateTime(1987, 07, 18),
    });
    marshalAttributes();
    installHostAttributes();
  }
}
