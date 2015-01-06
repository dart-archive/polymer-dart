// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @observable String bar = "baz";

  XFoo.created() : super.created();

  @ComputedProperty('bar')
  String get ignore => readValue(#bar);
}

class NullTreeSanitizer implements NodeTreeSanitizer {
  const NullTreeSanitizer();
  void sanitizeTree(Node node) {}
}
final nullSanitizer = const NullTreeSanitizer();

class NullNodeValidator implements NodeValidator {
  const NullNodeValidator();
  bool allowsAttribute(Element e, String a, String v) => true;
  bool allowsElement(Element element) => true;
}
final nullValidator = const NullNodeValidator();

main() => initPolymer().run(() {
  useHtmlConfiguration();

  XFoo xFoo;
  DivElement injectDiv;

  setUp(() => Polymer.onReady.then((_) {
    xFoo = querySelector('x-foo');
    injectDiv = xFoo.$['inject'];
  }));

  tearDown(() {
    injectDiv.innerHtml = '';
  });

  test('can inject bound html fragments', () {
    xFoo.injectBoundHtml('<span>{{bar}}</span>', element: injectDiv);
    expect(injectDiv.innerHtml, '<span>baz</span>');

    xFoo.bar = 'bat';
    return new Future(() {}).then((_) {
      expect(injectDiv.innerHtml, '<span>bat</span>');
    });
  });

  test('custom sanitizer and validator', () {
    var html = '<span style="color: black;"></span>';
    var sanitizedHtml = '<span></span>';

    // Expect it to sanitize by default.
    xFoo.injectBoundHtml(html, element: injectDiv);
    expect(injectDiv.innerHtml, sanitizedHtml);

    // Don't sanitize if we give it a dummy validator
    xFoo.injectBoundHtml(html, element: injectDiv, validator: nullValidator);
    expect(injectDiv.innerHtml, html);

    // Don't sanitize if we give it a dummy sanitizer
    xFoo.injectBoundHtml(
        html, element: injectDiv, treeSanitizer: nullSanitizer);
    expect(injectDiv.innerHtml, html);
  });
});
