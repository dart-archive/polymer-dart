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

  test('Elements fire property-changed events', () {
    var grandchildValueChanged = 0;
    grandchild.on['value-changed'].listen((_) {
      grandchildValueChanged++;
    });
    var childModelChanged = 0;
    child.on['model-changed'].listen((_) {
      childModelChanged++;
    });
    var parentModelChanged = 0;
    parent.on['model-changed'].listen((_) {
      parentModelChanged++;
    });

    // Deep child changes subproperty of model.
    grandchild.set('value', 1);
    expect(grandchildValueChanged, 1);
    expect(childModelChanged, 1);
    expect(parentModelChanged, 1);

    // Child changes model
    child.set('model', new Model(2));
    expect(grandchildValueChanged, 2);
    expect(childModelChanged, 2);
    expect(parentModelChanged, 2);

    // Parent changes model, but to one with the same value. Deep child should
    // not see change since its value didn't change.
    parent.set('model', new Model(2));
    expect(grandchildValueChanged, 2);
    expect(childModelChanged, 3);
    expect(parentModelChanged, 3);

    // Change property path from child.
    child.set('model.value', 3);
    expect(grandchildValueChanged, 3);
    expect(childModelChanged, 4);
    expect(parentModelChanged, 4);

    // Change property path to identical value, should get no events.
    grandchild.set('value', 3);
    expect(grandchildValueChanged, 3);
    expect(childModelChanged, 4);
    expect(parentModelChanged, 4);
  });
}

class Model extends JsProxy {
  int value;
  Model(this.value);
}

@PolymerRegister('parent-element')
class ParentElement extends PolymerElement {
  @Property(notify: true)
  Model model = defaultModel;

  ParentElement.created() : super.created();
}

@PolymerRegister('child-element')
class ChildElement extends PolymerElement {
  @Property(notify: true)
  Model model;

  ChildElement.created() : super.created();
}

@PolymerRegister('grandchild-element')
class GrandchildElement extends PolymerElement {
  @Property(notify: true)
  int value;

  GrandchildElement.created() : super.created();
}
