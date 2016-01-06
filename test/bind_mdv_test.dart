// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library polymer.test.bind_mdv_test;

import 'dart:async';
import 'dart:html';
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart' as mu; // make test smaller.
import 'common.dart';
import 'package:web_components/polyfill.dart';

/// Uses [mu].
main() {
  var registered = customElementsReady.then((_) {
    document.registerElement('my-div', MyDivElement);
  });

  setUp(() => registered);

  group('bindModel', bindModelTests);
}

bindModelTests() {
  var div;

  setUp(() {
    div = new MyDivElement();
    document.body.append(div);
  });

  tearDown(() {
    div.remove();
  });

  parseAndBindHTML(html, model) => templateBind(new Element.tag('template')
    ..setInnerHtml(html, treeSanitizer: const NullTreeSanitizer()))
      .createInstance(model);

  test('bindModel', () {
    var done = new Completer();
    var fragment = parseAndBindHTML('<div id="a" foo="{{bar}}"></div>', div);
    div.append(fragment);
    var a = div.query('#a');

    onAttributeChange(a).then((_) {
      expect(a.attributes['foo'], '5');
      onAttributeChange(a).then((_) {
        expect(a.attributes['foo'], '8');
        done.complete();
      });
      div.bar = 8;
    });
    div.bar = 5;

    return done.future;
  }, skip: 'https://github.com/dart-lang/polymer-dart/issues/78');

  test('bind input', () {
    var fragment = parseAndBindHTML('<input value="{{bar}}" />', div);
    div.append(fragment);
    var a = div.query('input');

    div.bar = 'hello';
    return new Future(() {
      expect(a.value, 'hello');
    });
  }, skip: 'https://github.com/dart-lang/polymer-dart/issues/78');
}

class MyDivElement extends HtmlElement with Observable {
  factory MyDivElement() => new Element.tag('my-div');
  MyDivElement.created() : super.created();
  @observable var bar;
}

class NullTreeSanitizer implements NodeTreeSanitizer {
  const NullTreeSanitizer();
  void sanitizeTree(Node node) {}
}

Future onAttributeChange(Element node) {
  var completer = new Completer();
  new MutationObserver((records, observer) {
    observer.disconnect();
    completer.complete();
  })..observe(node, attributes: true);
  scheduleMicrotask(Observable.dirtyCheck);
  return completer.future;
}
