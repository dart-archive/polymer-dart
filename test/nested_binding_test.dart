// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library polymer.test.nested_binding_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'common.dart';

@CustomTag('my-test')
class MyTest extends PolymerElement {
  final List fruits = toObservable(['apples', 'oranges', 'pears']);

  final onReady = new Completer();

  MyTest.created() : super.created();

  ready() {
    onReady.complete();
  }
}

main() => initPolymer().then((zone) => zone.run(() {
      setUp(() => Polymer.onReady);

      test('ready called', () async {
        var el = (querySelector('my-test') as MyTest);
        await el.onReady;
        expect(el.$['fruit'].text.trim(), 'Short name: [pears]');
      });
    }));
