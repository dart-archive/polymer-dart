// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.micro.attributes_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
// TODO(jakemac): `mixin` is only defined for polymer standard, but is used
// by attribute features in micro? May just need to update polymer js.
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;

AttributesTest element;

main() async {
  useHtmlConfiguration();
  smoke.useMirrors();
  await initPolymer();

  setUp(() {
    element = querySelector('attributes-test');
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
//    expect(DateTime.parse(element.attributes['host-date-time']),
//        new DateTime(1987, 07, 18));
  });
}

@PolymerRegister('attributes-test', hostAttributes: const {
  'host-string': 'string',
  'host-num': 2,
  'host-bool': true,
  'host-map': const {'hello': 'world'},
  'host-list': const ['hello', 'world'],
  // TODO(jakemac): Do we need to support this?
//  'host-date-time': new DateTime(1987, 07, 18),
})
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

  AttributesTest.created() : super.created();
}
