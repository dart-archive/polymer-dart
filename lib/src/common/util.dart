// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.util;

import 'dart:html';
import 'dart:js';
import 'package:reflectable/reflectable.dart';

/// Converts the static `hostAttributes` property of the supplied [ClassMirror]
/// to a [JsObject] and reports nice errors for failure cases.
JsObject readHostAttributes(ClassMirror classMirror) {
  if (!classMirror.staticMembers.containsKey('hostAttributes')) return null;
  var hostAttributes = classMirror.invokeGetter('hostAttributes');
  if (hostAttributes is! Map) {
    throw '`hostAttributes` on ${classMirror.simpleName} must be a `Map`, '
        'but got a ${hostAttributes.runtimeType}';
  }
  try {
    return new JsObject.jsify(hostAttributes);
  } catch (e) {
    window.console.error('''
Invalid value for `hostAttributes` on ${classMirror.simpleName}.
Must be a Map which is compatible with `new JsObject.jsify(...)`.

Original Exception:
$e''');
  }
}
