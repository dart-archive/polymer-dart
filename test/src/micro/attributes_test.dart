// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//@TestOn('browser')
library polymer.test.src.micro.attributes_test;

import 'dart:html';
import 'dart:js';
//import 'package:test/test.dart';
import 'package:unittest/unittest.dart';
import 'package:initialize/initialize.dart' show initMethod;
import 'package:polymer/polymer_micro.dart';
import 'package:smoke/mirrors.dart' as smoke;
import 'package:web_components/web_components.dart' show CustomElement;
export 'package:polymer/init.dart';

AttributesTest element;

@initMethod
ready() {
  smoke.useMirrors();

  setUp(() {
    element = querySelector('attributes-test');
  });

//  test('attributes can be marshalled into properties', () {
//    expect(element.myString, 'string');
//    expect(element.myNum, 2);
//    expect(element.myBool, true);
//    expect(element.myMap, {'hello': 'world'});
//    expect(element.myList, ['hello', 'world']);
//    expect(element.myDateTime, new DateTime(1987, 07, 18));
//  });

  test('hostAttributes are applied to the host', () {
    expect(element.attributes['host-string'], 'string');
    expect(element.attributes['host-num'], '2');
    expect(element.attributes['host-bool'], '');
    expect(element.attributes['host-map'], '{"hello":"world"}');
    expect(element.attributes['host-list'], '["hello","world"]');
//    expect(DateTime.parse(element.attributes['host-date-time']),
//        new DateTime(1987, 07, 18));
  });
}

@CustomElement('attributes-test')
class AttributesTest extends PolymerMicroElement {
  String myString;
  num myNum;
  bool myBool;
  Map myMap;
  List myList;
  DateTime myDateTime;


  AttributesTest.created() : super.created() {
    // Extra proxies for this element!
    context['Object'].callMethod('defineProperty', [
      jsThis,
      'myString',
      new JsObject.jsify({
        'get': () => myString,
        'set': (String newBaz) { myString = newBaz; },
      }),
    ]);

    hostAttributes.addAll({
      'host-string': 'string',
      'host-num': 2,
      'host-bool': true,
      'host-map': {'hello': 'world'},
      'host-list': ['hello', 'world'],
      'host-date-time': new DateTime(1987, 07, 18),
    });
    polymerCreated();
  }
}
