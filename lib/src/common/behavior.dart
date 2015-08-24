// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.behavior;

import 'dart:js';
import 'package:polymer_interop/polymer_interop.dart' show BehaviorAnnotation;
export 'package:polymer_interop/polymer_interop.dart'
    show BehaviorAnnotation, BehaviorProxy;
import 'package:reflectable/reflectable.dart';
import 'declarations.dart';
import 'js_proxy.dart';

Map<Type, JsObject> _behaviorsByType = {};

const String _lifecycleMethodsPattern =
    r'^created|attached|detached|attributeChanged|ready$';
final RegExp _lifecycleMethodsRegex = new RegExp(_lifecycleMethodsPattern);

// Annotation class for behaviors written in dart.
class Behavior extends Reflectable implements BehaviorAnnotation {
  JsObject getBehavior(Type type) {
    return _behaviorsByType.putIfAbsent(type, () {
      var obj = new JsObject(context['Object']);

      // Add an entry for each static lifecycle method. These methods must take
      // a `this` arg as the first argument.
      var typeMirror = this.reflectType(type);
      typeMirror.staticMembers.forEach((String name, MethodMirror method) {
        if (!_lifecycleMethodsRegex.hasMatch(name)) return;
        if (name == 'attributeChanged') {
          obj[name] = new JsFunction.withThis(
              (thisArg, String attributeName, Type type, value) {
            typeMirror.invoke(
                name, [dartValue(thisArg), attributeName, type, value]);
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

  const Behavior()
      : super(declarationsCapability, typeCapability, metadataCapability,
            const StaticInvokeCapability(_lifecycleMethodsPattern));
}

const behavior = const Behavior();

bool _isBehavior(instance) => instance is BehaviorAnnotation;
