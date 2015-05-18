// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.dart.micro.properties_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:initialize/initialize.dart';
import 'package:polymer/polymer_micro.dart';
export 'package:web_components/init.dart';

@initMethod
ready() {
  PropertiesTest element = document.createElement('properties-test');

  test('can get property info', () {
    expect(element.getPropertyInfo('myString'),
        new PropertyInfo(#myString, String));
    expect(element.getPropertyInfo('myInt'),
        new PropertyInfo(#myInt, int));
    expect(element.getPropertyInfo('myDouble'),
        new PropertyInfo(#myDouble, double));
    expect(element.getPropertyInfo('myNum'),
        new PropertyInfo(#myNum, num));
    expect(element.getPropertyInfo('myBool'),
        new PropertyInfo(#myBool, bool));
    expect(element.getPropertyInfo('myMap'),
        new PropertyInfo(#myMap, Map));
    expect(element.getPropertyInfo('myList'),
        new PropertyInfo(#myList, List));
    expect(element.getPropertyInfo('myDateTime'),
        new PropertyInfo(#myDateTime, DateTime));
  });
}

@CustomElement('properties-test')
class PropertiesTest extends HtmlElement with Properties {
  String myString;
  int myInt;
  double myDouble;
  num myNum;
  bool myBool;
  Map myMap;
  List myList;
  DateTime myDateTime;

  PropertiesTest.created() : super.created();
}
