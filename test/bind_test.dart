// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'common.dart';

@CustomTag('x-bar')
class XBar extends PolymerElement {
  XBar.created() : super.created();

  get testValue => true;
}

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @observable var foo = 'foo!';
  final _testReady = new Completer();
  Future get onTestReady => _testReady.future;

  XFoo.created() : super.created();

  runTest() {
    expect($['bindId'].text.trim(), 'bar!');

    expect(foo, $['foo'].attributes['foo']);
    expect($['bool'].attributes['foo'], '');
    expect($['bool'].attributes, isNot(contains('foo?')));
    expect($['content'].innerHtml, foo);

    expect(foo, $['bar'].attributes['foo']);
    expect($['barBool'].attributes['foo'], '');
    expect($['barBool'].attributes, isNot(contains('foo?')));
    expect($['barContent'].innerHtml, foo);
  }

  ready() {
    onMutation($['bindId']).then((_) => _testReady.complete());
  }
}

main() => initPolymer();

@whenPolymerReady
void runTests() {
  test('ready called', () async {
    var xFoo = querySelector('x-foo') as XFoo;
    await xFoo.onTestReady;
    xFoo.runTest();
  });
}
