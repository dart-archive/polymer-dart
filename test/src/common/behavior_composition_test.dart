// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library polymer.test.src.common.behavior_composition_test;

import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:polymer/src/common/polymer_descriptor.dart';
import 'package:test/test.dart';
import 'package:web_components/web_components.dart';
import '../../common.dart';

main() async {
  await initPolymer();

  group('behavior composition', () {
    test('Correct usage of mixins works', () {
      var descriptor =
          createPolymerDescriptor(Good, const PolymerRegister('good-element'));
      // Should only get [BehaviorFour] in the top level behaviors object.
      expect(descriptor['behaviors'].length, 1);

      var behaviorFour = behavior.getBehavior(BehaviorFour);
      expect(descriptor['behaviors'][0], behaviorFour);
      expect(behaviorFour, new isInstanceOf<JsArray>());
      expect(behaviorFour.length, 2);

      var behaviorThree = behavior.getBehavior(BehaviorThree);
      expect(behaviorFour[0], behaviorThree);
      expect(behaviorFour[1], new isInstanceOf<JsObject>());
      expect(behaviorThree, new isInstanceOf<JsArray>());
      expect(behaviorThree.length, 3);

      var behaviorTwo = behavior.getBehavior(BehaviorTwo);
      expect(behaviorTwo, new isInstanceOf<JsObject>());
      var behaviorOne = behavior.getBehavior(BehaviorOne);
      expect(behaviorOne, new isInstanceOf<JsObject>());

      expect(behaviorThree[0], behaviorOneProxy.getBehavior(BehaviorOne));
      expect(behaviorThree[1], behaviorTwo);
      expect(behaviorThree[2], new isInstanceOf<JsObject>());
    });

    test('Missing behavior mixins throw errors', () {
      expect(() {
        createPolymerDescriptor(
            Incomplete, const PolymerRegister('incomplete-element'));
      }, throwsA(contains('BehaviorOne, BehaviorTwo')));
    });

    test('Invalid ordering of mixins throws errors', () {
      expect(() {
        createPolymerDescriptor(
            Invalid, const PolymerRegister('invalid-element'));
      }, throwsA(contains('BehaviorOne, BehaviorTwo')));
    });
  });
}

const behaviorOneProxy = const BehaviorProxy(const ['JsBehavior']);
@behaviorOneProxy
abstract class BehaviorOne {}

@behavior
abstract class BehaviorTwo {}

@behavior
abstract class BehaviorThree implements BehaviorOne, BehaviorTwo {}

@behavior
abstract class BehaviorFour implements BehaviorThree {}

class Good extends PolymerElement
    with BehaviorOne, BehaviorTwo, BehaviorThree, BehaviorFour {
  Good.created() : super.created();
}

class Incomplete extends PolymerElement with BehaviorOne, BehaviorThree {
  Incomplete.created() : super.created();
}

class Invalid extends PolymerElement
    with BehaviorTwo, BehaviorOne, BehaviorThree {
  Invalid.created() : super.created();
}
