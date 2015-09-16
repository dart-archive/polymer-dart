// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.reflect_to_attribute_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

TestElement element;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-element');
  });

  group('can reflect values to attributes', () {
    test('String', () {
      expect(element.attributes['my-string'], 'myString');
      element.set('myString', 'newString');
      expect(element.attributes['my-string'], 'newString');
    });

    test('int', () {
      expect(element.attributes['my-int'], '1');
      element.set('myInt', 2);
      expect(element.attributes['my-int'], '2');
    });

    test('double', () {
      expect(element.attributes['my-double'], '2.5');
      element.set('myDouble', 1.5);
      expect(element.attributes['my-double'], '1.5');
    });

    test('bool', () {
      expect(element.attributes['my-bool'], isNull);
      element.set('myBool', true);
      expect(element.attributes['my-bool'], '');
    });

    test('List', () async {
      expect(element.attributes['my-list'], '[1]');
      element.set('myList', [2, 3]);
      expect(element.attributes['my-list'], '[2,3]');
      // TODO(jakemac): Restore once this bug is fixed in polymer js
      // https://github.com/Polymer/polymer/issues/1939
      // element.addAll('myList', [4, 5]);
      // expect(element.attributes['my-list'], '[4,5]');
    });

    test('Map', () {
      expect(element.attributes['my-map'], '{"foo":"bar"}');
      element.set('myMap', {'baz': 'zap'});
      expect(element.attributes['my-map'], '{"baz":"zap"}');
      // TODO(jakemac): Restore once this bug is fixed in polymer js
      // https://github.com/Polymer/polymer/issues/1939
      // element.set('myMap.oof', 'rap');
      // expect(element.attributes['my-map'], '{"baz":"zap","oof":"rap"}');
    });

    // TODO(jakemac): Figure out what to do for DateTime.
    // test('DateTime', () {
    // });
  });
}

@PolymerRegister('test-element')
class TestElement extends PolymerElement {
  @Property(reflectToAttribute: true)
  String myString = 'myString';

  @Property(reflectToAttribute: true)
  int myInt = 1;

  @Property(reflectToAttribute: true)
  double myDouble = 2.5;

  @Property(reflectToAttribute: true)
  bool myBool = false;

  @Property(reflectToAttribute: true)
  List myList = [1];

  @Property(reflectToAttribute: true)
  Map myMap = {'foo': 'bar'};

  // TODO(jakemac): Figure out what to do for DateTime.
  // @Property(reflectToAttribute: true)
  // DateTime myDate = new DateTime(1998, 9, 4);

  TestElement.created() : super.created();
}
