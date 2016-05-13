// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.standard.property_change_notification_test;

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

  test('Children can notify parents of changes', () {
    expect(parent.model, defaultModel);
    expect(child.model, defaultModel);
    expect(grandchild.value, defaultModel.value);

    var newModel = new Model(1);
    child.set('model', newModel);
    expect(parent.model, newModel);
    expect(grandchild.value, newModel.value);

    grandchild.set('value', 2);
    expect(newModel.value, 2);
    expect(child.model.value, 2);
    expect(parent.model.value, 2);
  });

  test('Elements fire property-changed events', () async {
    expect(grandchild.valueChangedCount, 1);
    expect(child.modelChangedCount, 1);
    expect(parent.modelChangedCount, 1);

    // Deep child changes subproperty of model.
    grandchild.set('value', 1);
    expect(grandchild.valueChangedCount, 2);
    expect(child.modelChangedCount, 2);
    expect(parent.modelChangedCount, 2);

    // Child changes model
    child.set('model', new Model(2));
    await PolymerRenderStatus.afterNextRender(grandchild);
    expect(grandchild.valueChangedCount, 3);
    expect(child.modelChangedCount, 3);
    expect(parent.modelChangedCount, 3);

    // Parent changes model, but to one with the same value. Deep child should
    // not see change since its value didn't change.
    parent.set('model', new Model(2));
    expect(grandchild.valueChangedCount, 3);
    expect(child.modelChangedCount, 4);
    expect(parent.modelChangedCount, 4);

    // Change property path from child.
    child.set('model.value', 3);
    expect(grandchild.valueChangedCount, 4);
    expect(child.modelChangedCount, 5);
    expect(parent.modelChangedCount, 5);

    // Change property path to identical value, should get no events.
    grandchild.set('value', 3);
    expect(grandchild.valueChangedCount, 4);
    expect(child.modelChangedCount, 5);
    expect(parent.modelChangedCount, 5);
  });
}

class Model extends JsProxy {
  @reflectable
  int value;

  Model(this.value);
}

@PolymerRegister('parent-element')
class ParentElement extends PolymerElement {
  @Property(notify: true)
  Model model = defaultModel;

  int modelChangedCount = 0;

  @Observe('model.*')
  modelChanged(_) {
    modelChangedCount++;
  }

  ParentElement.created() : super.created();
}

@PolymerRegister('child-element')
class ChildElement extends PolymerElement {
  @Property(notify: true)
  Model model;

  int modelChangedCount = 0;

  @Observe('model.*')
  modelChanged(_) {
    modelChangedCount++;
  }

  ChildElement.created() : super.created();
}

@PolymerRegister('grandchild-element')
class GrandchildElement extends PolymerElement {
  @Property(notify: true)
  int value;

  int valueChangedCount = 0;

  @Observe('value')
  valueChanged(_) {
    valueChangedCount++;
  }

  GrandchildElement.created() : super.created();
}
