// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.property;

import 'reflectable.dart';

/// Use this to mark a field on a class as a polymer property.
class Property extends PolymerReflectable {
  /// Fire *-change events to support two way binding.
  final bool notify;

  /// Name of a method to call when the property changes.
  final String observer;

  /// Whether or not this property should be reflected back to the attribute.
  final bool reflectToAttribute;

  /// Provided for computed properties.
  final String computed;

  const Property(
      {this.notify: false,
      this.observer,
      this.reflectToAttribute: false,
      this.computed});
}

const property = const Property();
