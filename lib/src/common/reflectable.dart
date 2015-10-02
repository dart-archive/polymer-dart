// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.reflectable;

/// Indicates that a field or method is reflectable. This means it will be
/// available to templates and any other string references.
class PolymerReflectable {
  const PolymerReflectable();
}

const reflectable = const PolymerReflectable();
