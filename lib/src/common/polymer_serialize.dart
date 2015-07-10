// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_serialize;

import 'dart:js';
import 'js_proxy.dart';
import 'polymer_mixin.dart';
import 'polymer_descriptor.dart';

/// Mixin for Polymer serialization methods.
///
/// This should only be used if the [serialize] and [deserialize] methods need
/// to be overriden to support additional Dart types. Any types not explicitly
/// handled by the overriden method should defer to the original method by
/// calling the base class's implementation.
abstract class PolymerSerialize implements PolymerMixin {
  JsObject get jsElement;

  /// Serializes the [value] into a [String].
  String serialize(Object value) {
    return jsElement.callMethod('originalSerialize', [jsValue(value)]).toString();
  }

  /// Deserializes the [value] into an object of the given [type].
  Object deserialize(String value, Type type) {
    return dartValue(jsElement.callMethod('originalDeserialize',
        [jsValue(value), jsType(type)]));
  }
}
