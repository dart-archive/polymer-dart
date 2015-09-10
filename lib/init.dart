// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.init;

import 'dart:async';
import 'dart:js';
import 'package:reflectable/reflectable.dart';
import 'package:web_components/web_components.dart';
import 'src/common/js_proxy.dart';
import 'src/common/polymer_register.dart';

main() => initPolymer();

Future initPolymer() async {
  await initWebComponents(typeFilter: [HtmlImport], initAll: false);
  // Make sure polymer is loaded first.
  _setUpPropertyChanged();
  await initWebComponents(
      typeFilter: [CustomElement, CustomElementProxy, PolymerRegister],
      initAll: true);
}

final _polymerDart = context['Polymer']['Dart'];

void _setUpPropertyChanged() {
  _polymerDart['propertyChanged'] = (instance, String path, newValue) {
    if (instance is List) {
      if (path == 'splices') {
        // Only apply splices once, if multiple elements have a binding set up
        // for the same list then they will each get called here.
        var alreadyApplied = newValue['_applied'];
        if (alreadyApplied == true) return;
        newValue['_applied'] = true;

        var splices = newValue['indexSplices'];
        for (var splice in splices) {
          var index = splice['index'];
          var removed = splice['removed'];
          if (removed != null && removed.length > 0) {
            instance.removeRange(index, index + removed.length);
          }
          var addedCount = splice['addedCount'];
          var original = splice['object'] as JsArray;
          instance.insertAll(
              index, original.getRange(index, addedCount + index).map(dartValue));
        }
        return;
      } else if (path == 'length') {
        // no-op, wait for `splices`.
        return;
      }
    }
    var instanceMirror = jsProxyReflectable.reflect(instance);
    // Read only property?
    if (instanceMirror.type.instanceMembers['$path'] is! VariableMirror &&
        instanceMirror.type.instanceMembers['$path='] == null) {
      return;
    }
    instanceMirror.invokeSetter(path, dartValue(newValue));
  };
}
