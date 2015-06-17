// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.common.js_proxy;

import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

class MyModel extends Object with JsProxy {
  int value = 0;
  int get readOnlyVal => 1;
  final finalVal = 1;

  int incrementBy([int amount = 1]) => value += amount;
}

class CachedMyModel extends MyModel {
  CachedMyModel() {
    useCache = true;
  }
}

MyModel model;
JsObject proxy;
CachedMyModel cachedModel;
JsObject cachedModelProxy;

main() async {
  smoke.useMirrors();
  useHtmlConfiguration();
  await initPolymer();

  setUp(() {
    model = new MyModel();
    proxy = model.jsProxy;
    cachedModel = new CachedMyModel();
    cachedModelProxy = cachedModel.jsProxy;
  });

  test('proxy has reference to the original dart object', () {
    expect(proxy['__dartClass__'], model);
  });

  test('can read and write values via the proxy', () {
    expect(proxy['value'], model.value);
    model.incrementBy(10);
    expect(proxy['value'], model.value);
    proxy['value'] = 15;
    expect(model.value, 15);
  });

  test('can call methods via the proxy', () {
    expect(proxy.callMethod('incrementBy', [5]), 5);
    expect(model.value, 5);
  });

  test('read only fields have getters but not setters', () {
    // Doesn't actually throw unless in strict mode.
    proxy['readOnlyVal'] = 2;
    proxy['finalVal'] = 3;

    expect(model.readOnlyVal, 1);
    expect(model.finalVal, 1);
  });

  test('useCache caches values on the js object', () {
    expect(cachedModelProxy['value'], isNull);
    cachedModelProxy['value'] = 10;
    expect(cachedModelProxy['value'], 10);
    expect(cachedModel.value, 10);
    cachedModel.value = 5;
    expect(cachedModelProxy['value'], 10);
  });
}
