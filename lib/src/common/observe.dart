// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.observe;

import 'reflectable.dart';

/// Annotation class for methods, should match the argument string portion of
/// a regular `observers` entry from polymer js, see
/// https://www.polymer-project.org/1.0/docs/devguide/properties.html#multi-property-observers
/// for more details.
///
/// For example, given this `observers` object in js:
///
///   observers: [
///     'updateImage(preload, src, size)'
///   ]
///
/// This would the the equivalent using the [Observe] annotation:
///
///   @Observe('preload, src, size`)
///   updateImage(bool preload, String src, String size) {
///     ...
///   }
class Observe extends PolymerReflectable {
  final String properties;
  const Observe(this.properties) : super();
}
