// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.js_proxy_test;

import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

class EmptyModel {}

class MyModel extends Object with JsProxy {
  @reflectable
  int value = 0;

  @reflectable
  int get readOnlyVal => 1;

  @reflectable
  final finalVal = 1;

  @reflectable
  int get getterSetterVal => _getterSetterVal;
  void set getterSetterVal(int value) {
    _getterSetterVal = value;
  }
  int _getterSetterVal = 1;

  @reflectable
  int incrementBy([int amount = 1]) => value += amount;
}

class CachedMyModel extends MyModel {
  CachedMyModel() {
    useCache = true;
  }
}

MyModel model;
CachedMyModel cachedModel;

main() async {
  await initPolymer();

  group('basic', () {
    setUp(() {
      model = new MyModel();
      cachedModel = new CachedMyModel();
    });

    test('proxy has reference to the original dart object', () {
      expect(model.jsProxy['__dartClass__'], model);
    });

    test('can read and write values via the proxy', () {
      expect(model.jsProxy['value'], model.value);
      model.incrementBy(10);
      expect(model.jsProxy['value'], model.value);
      model.jsProxy['value'] = 15;
      expect(model.value, 15);
    });

    test('can call methods via the proxy', () {
      expect(model.jsProxy.callMethod('incrementBy', [5]), 5);
      expect(model.value, 5);
    });

    test('read only fields have getters but not setters', () {
      // Doesn't actually throw unless in strict mode.
      model.jsProxy['readOnlyVal'] = 2;
      model.jsProxy['finalVal'] = 3;

      expect(model.readOnlyVal, 1);
      expect(model.finalVal, 1);
    });

    test('getter/setter fields only need to annotate the getter', () {
      expect(model.getterSetterVal, 1);
      expect(model.jsProxy['getterSetterVal'], 1);

      model.jsProxy['getterSetterVal'] = 4;
      expect(model.getterSetterVal, 4);
      expect(model.jsProxy['getterSetterVal'], 4);
    });

    test('useCache caches values on the js object', () {
      expect(cachedModel.jsProxy['value'], isNull);
      cachedModel.jsProxy['value'] = 10;
      expect(cachedModel.jsProxy['value'], 10);
      expect(cachedModel.value, 10);
      cachedModel.value = 5;
      expect(cachedModel.jsProxy['value'], 10);
    });
  });
}
