// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.init;

import 'dart:async';
import 'dart:js';
import 'package:web_components/web_components.dart';
import 'src/common/js_proxy.dart';
import 'src/common/polymer_register.dart';

main() => initPolymer();

Future initPolymer() async {
  await initWebComponents(typeFilter: [HtmlImport], initAll: false);
  // Make sure `src/js/polymer_array_methods.html` is loaded first.
  _setUpListMethods();
  await initWebComponents(
      typeFilter: [CustomElement, CustomElementProxy, PolymerRegister],
      initAll: true);
}

void _setUpListMethods() {
  var polymerDart = context['Polymer']['Dart'];
  polymerDart['push'] = (List list, Iterable items) {
    list.addAll(items.map((item) => dartValue(item)));
  };
  polymerDart['pop'] = (List list) => list.removeLast();
  polymerDart['shift'] = (List list) => list.removeAt(0);
  polymerDart['unshift'] = (List list, Iterable items) {
    list.insertAll(0, items.map((item) => dartValue(item)));
  };
  polymerDart['splice'] = (List list, int start, int deleteCount, Iterable items) {
    if (start < 0) start = list.length + start;
    if (deleteCount > 0) list.removeRange(start, start + deleteCount);
    list.insertAll(start, items.map((item) => dartValue(item)));
  };
}
