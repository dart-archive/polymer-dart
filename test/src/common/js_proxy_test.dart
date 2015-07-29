// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.js_proxy_test;

import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

class EmptyModel {}

@jsProxyReflectable
class MyModel extends Object with JsProxy {
  int value = 0;
  int get readOnlyVal => 1;
  final finalVal = 1;

  int incrementBy([int amount = 1]) => value += amount;
}

@jsProxyReflectable
class CachedMyModel extends MyModel {
  CachedMyModel() {
    useCache = true;
  }
}

MyModel model;
CachedMyModel cachedModel;

main() async {
  await initPolymer();

  setUp(() {
    model = new MyModel();
    cachedModel = new CachedMyModel();
  });

  group('basic', () {
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

    test('useCache caches values on the js object', () {
      expect(cachedModel.jsProxy['value'], isNull);
      cachedModel.jsProxy['value'] = 10;
      expect(cachedModel.jsProxy['value'], 10);
      expect(cachedModel.value, 10);
      cachedModel.value = 5;
      expect(cachedModel.jsProxy['value'], 10);
    });
  });

  group('dartValue', () {
    test('array', () {
      var model = new MyModel();
      var array = new JsArray.from([1, jsValue(model), 'a']);
      var dartList = dartValue(array) as List;
      expect(dartList, [1, model, 'a']);
      expect(array['__dartClass__'], dartList);
    });

    test('proxy array', () {
      var model = new MyModel();
      var list = [1, model, 'a'];
      var array = jsValue(list) as JsArray;
      expect(dartValue(array), list);
    });

    test('object', () {
      var model = new MyModel();
      var object =
          new JsObject.jsify({'1': 1, 'model': jsValue(model), 'a': 'a',});
      var dartMap = dartValue(object) as Map;
      expect(dartMap, {'1': 1, 'model': model, 'a': 'a',});
      expect(object['__dartClass__'], dartMap);
    });

    test('proxy object', () {
      var model = new MyModel();
      var map = {'1': 1, 'model': model, 'a': 'a',};
      var object = jsValue(map) as JsObject;
      expect(dartValue(object), map);
    });

    test('custom js objects are left alone', () {
      var constructor = new JsFunction.withThis((_) {});
      var object = new JsObject(constructor);
      expect(dartValue(object), object);
    });

    test('Date objects', () {
      var jsDate = new JsObject(context['Date'], [1000]);
      var dartDate = dartValue(jsDate) as DateTime;
      expect(dartDate.millisecondsSinceEpoch, 1000);
    });
  });

  group('jsValue', () {
    test('JsProxy objects', () {
      var model = new MyModel();
      expect(jsValue(model), model.jsProxy);
    });

    test('JsObject objects', () {
      var object = new JsObject(context['Object']);
      expect(jsValue(object), object);
    });

    test('Iterables', () {
      var model = new MyModel();
      var list = [1, model, 2];
      var jsArray = jsValue(list) as JsArray;
      expect(jsArray, new JsArray.from([1, model.jsProxy, 2]));
      expect(jsArray['__dartClass__'], list);
    });

    test('Maps', () {
      var model = new MyModel();
      var map = {'1': 1, 'model': model, 'a': 'a',};
      var jsObject = jsValue(map) as JsObject;
      expectEqual(jsObject, {
        '1': 1,
        'model': model.jsProxy,
        'a': 'a',
        '__dartClass__': map,
      });
    });

    test('Arbitrary class', () {
      var model = new EmptyModel();
      expect(jsValue(model), model);
    });

    test('DateTime objects', () {
      var dartDate = new DateTime.fromMillisecondsSinceEpoch(1000);
      var jsDate = jsValue(dartDate);
      expect(jsDate.callMethod('getTime'), 1000);
    });
  });
}

void expectEqual(JsObject actual, Map expected) {
  var keys = context['Object'].callMethod('keys', [actual]);
  for (var key in keys) {
    expect(expected[key], actual[key]);
  }
}
