// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'common.dart';

@CustomTag('x-test')
class XTest extends PolymerElement {
  @observable List list;

  final _onAttached = new Completer();
  Future get onAttached => _onAttached.future;

  XTest.created() : super.created();

  attached() {
    super.attached();
    _onAttached.complete();
  }

  runTest() async {
    list = [{'name': 'foo'}, {'name': 'bar'}];
    await new Future(() {});
    // tickle SD polyfill
    offsetHeight;
    await new Future(() {});
    var children = $['echo'].children;
    expect(children[0].localName, 'template',
        reason: 'shadowDOM dynamic distribution via template');
    expect(children[1].text, 'foo',
        reason: 'shadowDOM dynamic distribution via template');
    expect(children[2].text, 'bar',
        reason: 'shadowDOM dynamic distribution via template');
    expect(children.length, 3, reason: 'expected number of children');
  }
}

main() => initPolymer();

@whenPolymerReady
runTests() {
  test('inserted called', () async {
    var el = (querySelector('x-test') as XTest);
    await el.onAttached;
    await el.runTest();
  });
}
