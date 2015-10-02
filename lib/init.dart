// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.init;

import 'dart:async';
import 'dart:js';
import 'dart:html';
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
  // TODO(jakemac): Better solution to this, see
  // https://github.com/dart-lang/polymer-dart/issues/611
  document.body.attributes.remove('unresolved');
}

final _polymerDart = context['Polymer']['Dart'];

void _setUpPropertyChanged() {
  _polymerDart['propertyChanged'] = (instance, path, newValue) {
    if (instance is List) {
      // We only care about `splices` for Lists. This does mean we don't support
      // setting special properties of custom List implementations though.
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
          instance.insertAll(index,
              original.getRange(index, addedCount + index).map(convertToDart));
        }
      } else if (path == 'length') {
        // Ignore this case, wait for `splices`.
        return;
      } else if (path is int) {
        instance[path] = convertToDart(newValue);
      } else {
        throw 'Only `splices`, `length`, and index paths are supported for '
            'list types, found $path.';
      }
    } else if (instance is Map) {
      instance[path] = convertToDart(newValue);
    } else {
      var instanceMirror = jsProxyReflectable.reflect(instance);
      // Catch errors for read only properties. Checking for setters using
      // reflection is too slow.
      // https://github.com/dart-lang/polymer-dart/issues/590
      try {
        instanceMirror.invokeSetter(path, convertToDart(newValue));
      } on NoSuchMethodError catch (_) {} on NoSuchCapabilityError catch (_) {
        // TODO(jakemac): Remove once
        // https://github.com/dart-lang/reflectable/issues/30 is fixed.

      }
    }
  };
}
