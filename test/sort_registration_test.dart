// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.sort_registration_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

part 'sort_registration_part1.dart';
part 'sort_registration_part2.dart';

@CustomTag('x-a')
class A extends PolymerElement {
  A.created() : super.created();
}

main() => initPolymer().then((zone) => zone.run(() {
  useHtmlConfiguration();
  setUp(() => Polymer.onReady);

  test('registration is done in the right order', () {
    expect(querySelector('x-e') is E, isTrue);
  });
}));
