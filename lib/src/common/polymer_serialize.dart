// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
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
/// to be overridden to support additional Dart types. Any types not explicitly
/// handled by the overridden method should defer to the original method by
/// calling the base class's implementation.
abstract class PolymerSerialize implements PolymerMixin {
  JsObject get jsElement;

  /// Serializes the [value] into a [String].
  String serialize(value) {
    var result = _polymerDartSerialize.apply([convertToJs(value)]);

    return (result != null) ? result.toString() : null;
  }

  /// Deserializes the [value] into an object of the given [type].
  dynamic deserialize(String value, Type type) {
    return convertToDart(_polymerDartDeserialize.apply([value, jsType(type)]));
  }
}

final JsObject _polymer = context['Polymer'];
final JsFunction _polymerDartSerialize = _polymer['Dart']['serialize'];
final JsFunction _polymerDartDeserialize = _polymer['Dart']['deserialize'];
