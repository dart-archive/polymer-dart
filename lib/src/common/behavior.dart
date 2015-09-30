// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.behavior;

import 'dart:html';
import 'dart:js';
import 'package:polymer_interop/polymer_interop.dart' show BehaviorAnnotation;
export 'package:polymer_interop/polymer_interop.dart'
    show BehaviorAnnotation, BehaviorProxy;
@GlobalQuantifyMetaCapability(Behavior, jsProxyReflectable)
import 'package:reflectable/reflectable.dart';
import 'util.dart';
import 'js_proxy.dart';

Map<Type, JsObject> _behaviorsByType = {};

final RegExp _lifecycleMethodsRegex =
    new RegExp('created|attached|detached|attributeChanged|ready');
const String _hostAttributes = 'hostAttributes';
const String _attributeChanged = 'attributeChanged';

// Annotation class for behaviors written in dart.
class Behavior implements BehaviorAnnotation {
  JsObject getBehavior(Type type) {
    return _behaviorsByType.putIfAbsent(type, () {
      var obj = new JsObject(context['Object']);
      var typeMirror = jsProxyReflectable.reflectType(type);

      var hostAttributes = readHostAttributes(typeMirror);
      if (hostAttributes != null) {
        obj[_hostAttributes] = hostAttributes;
      }

      // Add an entry for each static lifecycle method. These methods must take
      // a `this` arg as the first argument.
      typeMirror.staticMembers.forEach((String name, MethodMirror method) {
        if (!_lifecycleMethodsRegex.hasMatch(name)) return;
        if (name == _attributeChanged) {
          obj[name] = new JsFunction.withThis(
              (thisArg, String attributeName, String oldVal, String newVal) {
            typeMirror.invoke(
                name, [convertToDart(thisArg), attributeName, oldVal, newVal]);
          });
        } else {
          obj[name] = new JsFunction.withThis((thisArg) {
            typeMirror.invoke(name, [thisArg]);
          });
        }
      });

      // Check superinterfaces for additional behaviors.
      var behaviors = [];
      for (var interface in typeMirror.superinterfaces) {
        var meta =
            interface.metadata.firstWhere(_isBehavior, orElse: () => null);
        if (meta == null) continue;
        behaviors.add(meta.getBehavior(interface.reflectedType));
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
