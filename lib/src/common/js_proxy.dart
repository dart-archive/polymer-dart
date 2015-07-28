// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.js_proxy;

import 'dart:js';
import 'dart:html';
import 'package:polymer_interop/polymer_interop.dart';
export 'package:polymer_interop/polymer_interop.dart' show dartValue, jsValue;
import 'package:reflectable/reflectable.dart';

// Mixin this class to get js proxy support!
abstract class JsProxy implements JsProxyInterface {
  /// Lazily create proxy constructors!
  static Map<Type, JsFunction> _jsProxyConstructors = {};

  /// Never reads from the dart object, instead reads properties from the
  /// `__cache__` object. This is primarily useful for objects that you pass in
  /// empty, and the javascript code will populate. It should be used carefully
  /// since its easy to get the two objects out of sync.
  bool useCache = false;

  /// The Javascript constructor that will be used to build proxy objects for
  /// this class.
  JsFunction get jsProxyConstructor {
    var type = runtimeType;
    return _jsProxyConstructors.putIfAbsent(
        type, () => _buildJsConstructorForType(type));
  }

  JsObject _jsProxy;
  JsObject get jsProxy {
    if (_jsProxy == null) _jsProxy = _buildJsProxy(this);
    return _jsProxy;
  }
}

/// Wraps an instance of a dart class in a js proxy.
JsObject _buildJsProxy(JsProxy instance) {
  var constructor = instance.jsProxyConstructor;
  var proxy = new JsObject(constructor);
  addDartInstance(proxy, instance);
  if (instance.useCache) {
    proxy['__cache__'] = new JsObject(context['Object']);
  }

  return proxy;
}

class JsProxyReflectable extends Reflectable {
  const JsProxyReflectable() : super(instanceInvokeCapability);
}
const jsProxyReflectable = const JsProxyReflectable();

final JsObject _polymerDart = context['Polymer']['Dart'];

/// Given a dart type, this creates a javascript constructor and prototype
/// which can act as a proxy for it.
JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = _polymerDart.callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  ClassMirror mirror;
  try {
    mirror = jsProxyReflectable.reflectType(dartType);
  } catch (e) {
    throw 'type $dartType is missing the @jsProxyReflectable annotation';
  }
  var declarations = new Map.from(mirror.declarations);
  var superClass;
  // Currently crashes post-transform if superclass isn't annotated with
  // Reflectable.
  try {
    superClass = mirror.superclass;
  } catch(e) {
    superClass = null;
  }

  while (superClass != null && superClass.reflectedType != Object) {
    superClass.declarations.forEach((k, v) {
      if (declarations.containsKey(k)) return;
      declarations[k] = v;
    });
    // Currently crashes post-transform if superclass isn't annotated with
    // Reflectable.
    try {
      superClass = superClass.superclass;
    } catch(e) {
      superClass = null;
    }
  }

  declarations.forEach((String name, DeclarationMirror declaration) {
    if (declaration is VariableMirror) {
      var descriptor = {
        'get': _polymerDart.callMethod('propertyAccessorFactory', [
          name,
          (dartInstance) {
            var mirror = jsProxyReflectable.reflect(dartInstance);
            return jsValue(mirror.invokeGetter(name));
          }
        ]),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = _polymerDart.callMethod('propertySetterFactory', [
          name,
          (dartInstance, value) {
            var mirror = jsProxyReflectable.reflect(dartInstance);
            mirror.invokeSetter(name, dartValue(value));
          }
        ]);
      }
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod(
          'defineProperty', [prototype, name, new JsObject.jsify(descriptor),]);
    } else if (declaration is MethodMirror) {
      // TODO(jakemac): consolidate this code with the code in properties.dart.
      prototype[name] = _polymerDart.callMethod('invokeDartFactory', [
        (dartInstance, arguments) {
          var newArgs = arguments.map((arg) => dartValue(arg)).toList();
          var mirror = jsProxyReflectable.reflect(dartInstance);
          return mirror.invoke(name, newArgs);
        }
      ]);
    }
  });

  constructor['prototype'] = prototype;
  return constructor;
}
