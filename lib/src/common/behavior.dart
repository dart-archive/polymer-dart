// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.behavior;

import 'dart:js';

import 'package:polymer_interop/polymer_interop.dart' show BehaviorAnnotation;
export 'package:polymer_interop/polymer_interop.dart'
    show BehaviorAnnotation, BehaviorProxy;
@GlobalQuantifyMetaCapability(Behavior, jsProxyReflectable)
import 'package:reflectable/reflectable.dart';

import 'js_proxy.dart';
import 'polymer_descriptor.dart';

Map<Type, JsObject> _behaviorsByType = {};

/// Custom js object containing some helper methods for dart.
final JsObject _polymerDart = context['Polymer']['Dart'];

// Annotation class for behaviors written in dart.
class Behavior implements BehaviorAnnotation {
  JsObject getBehavior(Type type) {
    return _behaviorsByType.putIfAbsent(type, () {
      var obj = createBehaviorDescriptor(type);
      ClassMirror typeMirror = jsProxyReflectable.reflectType(type);

      // Check superinterfaces for additional behaviors.
      var behaviors = [];
      for (var interface in typeMirror.superinterfaces) {
        var meta =
            interface.metadata.firstWhere(_isBehavior, orElse: () => null);
        if (meta == null) continue;
        if (!interface.hasBestEffortReflectedType) {
          throw 'Unable to get `bestEffortReflectedType` for class '
              '${interface.simpleName}.';
        }
        behaviors.add(meta.getBehavior(interface.bestEffortReflectedType));
      }

      // If we have no additional behaviors, then just return `obj`.
      if (behaviors.isEmpty) return obj;

      // If we do have dependent behaviors, return the list of all of them,
      // adding `obj` to the end.
      behaviors.add(obj);
      return new JsArray.from(behaviors);
    });
  }

  const Behavior();
}

const behavior = const Behavior();

bool _isBehavior(instance) => instance is BehaviorAnnotation;
