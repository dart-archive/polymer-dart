// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.src.standard.property_binding_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;

ParentElement parent;
ChildElement child;
GrandchildElement grandchild;
Model defaultModel = new Model(0);

main() async {
  useHtmlConfiguration();
  smoke.useMirrors();
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

class Model extends Object with JsProxy {
  int value;
  Model(this.value);
}

@PolymerRegister('parent-element')
class ParentElement extends PolymerElement {
  @property
  Model model = defaultModel;

  ParentElement.created() : super.created();
}

@PolymerRegister('child-element')
class ChildElement extends PolymerElement {
  @property
  Model model;

  ChildElement.created() : super.created();
}

@PolymerRegister('grandchild-element')
class GrandchildElement extends PolymerElement {
  @property
  int value;

  GrandchildElement.created() : super.created();
}
