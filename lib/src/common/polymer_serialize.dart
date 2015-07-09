// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_serialize;

/// Mixin for Polymer serialization methods.
abstract class PolymerSerialize {
  String serialize(Object value) {
    // Null signals to Polymer.js to use the JS path
    return null;
  }

  Object deserialize(String value, dynamic type) {
    // Null signals to Polymer.js to use the JS path
    return null;
  }
}
