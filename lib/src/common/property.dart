// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.property;

class Property {
  /// Fire *-change events to support two way binding.
  final bool notify;

  const Property({this.notify: false});
}

const property = const Property();
