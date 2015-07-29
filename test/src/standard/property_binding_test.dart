// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.property_binding_test;

import 'dart:html';
import 'package:test/test.dart';
import 'package:polymer/polymer.dart';

ParentElement parent;
ChildElement child;
GrandchildElement grandchild;
Model defaultModel = new Model(0);

main() async {
  await initPolymer();

  setUp(() {
    parent = document.createElement('parent-element');
    child = parent.$['child'];
    grandchild = child.$['grandchild'];
  });

  test('Properties can be bound to children', () {
    expect(parent.model, defaultModel);
    expect(child.model, defaultModel);

    var newModel = new Model(1);
    parent.set('model', newModel);
    expect(parent.model, newModel);
    expect(child.model, newModel);
  });

  test('Property paths can be bound to children', () {
    expect(grandchild.value, defaultModel.value);

    var newModel = new Model(1);
    parent.set('model', newModel);
    expect(grandchild.value, newModel.value);

    parent.set('model.value', 2);
    expect(grandchild.value, 2);
  });
}

@jsProxyReflectable
class Model extends Object with JsProxy {
  int value;
  Model(this.value);
}

@jsProxyReflectable
@PolymerRegister('parent-element')
class ParentElement extends PolymerElement {
  @property
  Model model = defaultModel;

  ParentElement.created() : super.created();
}

@jsProxyReflectable
@PolymerRegister('child-element')
class ChildElement extends PolymerElement {
  @property
  Model model;

  ChildElement.created() : super.created();
}

@jsProxyReflectable
@PolymerRegister('grandchild-element')
class GrandchildElement extends PolymerElement {
  @property
  int value;

  GrandchildElement.created() : super.created();
}
