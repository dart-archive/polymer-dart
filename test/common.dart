//Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
//for details. All rights reserved. Use of this source code is governed by a
//BSD-style license that can be found in the LICENSE file.
library polymer_dart.test.common;

import 'dart:async';
import 'dart:html';

Future wait(int milliseconds) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}

/// Given an `id` of a `<template>` element, this imports its content into the
/// current document and sets the content of `div#testContainer` to the result.
/// If that div does not already exist it will be created and appended to the
/// body.
///
/// If the template contains one child then it will return that child, otherwise
/// it will return a list of all children.
fixture(String id) {
  var container = document.querySelector('#testContainer');
  if (container == null) {
    container = new Element.html('<div id="testContainer"></div>');
    document.body.append(container);
  }
  container.children.clear();

  var elements = new List.from((document.importNode(
      (querySelector('#$id') as TemplateElement).content,
      true) as DocumentFragment).children);
  for (var element in elements) {
    container.append(element);
  }
  return elements.length == 1 ? elements[0] : elements;
}
