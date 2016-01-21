// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';

import 'package:reflectable/reflectable.dart';

import 'behavior.dart';
import 'declarations.dart';
import 'js_proxy.dart';
import 'listen.dart';
import 'observe.dart';
import 'polymer_register.dart';
import 'property.dart';
import 'reflectable.dart';
import 'util.dart';
import '../js/undefined.dart';

/// Creates a javascript object which can be passed to polymer js to register
/// an element, given a dart [Type] and a [PolymerRegister] annotation.
JsObject createPolymerDescriptor(Type type, PolymerRegister annotation) {
  return _createDescriptor(type)
    ..['is'] = annotation.tagName
    ..['extends'] = annotation.extendsTag
    ..['behaviors'] = _buildBehaviorsList(type);
}

/// Creates a javascript object which can be used as a behavior by polymer js,
/// given a dart [Type] and a [PolymerRegister] annotation.
JsObject createBehaviorDescriptor(Type type) {
  return _createDescriptor(type, true);
}

/// Shared descriptor between polymer elements and behaviors
JsObject _createDescriptor(Type type, [bool isBehavior = false]) {
  var descriptor = new JsObject.jsify({
    'properties': _buildPropertiesObject(type),
    'observers': _buildObserversObject(type),
    'listeners': _buildListenersObject(type),
    '__isPolymerDart__': true,
  });
  _setupLifecycleMethods(type, descriptor, isBehavior);
  _setupReflectableMethods(type, descriptor);
  _setupReflectableProperties(type, descriptor);
  _setupHostAttributes(type, descriptor);
  _setupRegistrationMethods(type, descriptor);

  return descriptor;
}

/// Custom js object containing some helper methods for dart.
final JsObject _polymerDart = context['Polymer']['Dart'];

/// Returns a list of [DeclarationMirror]s for all fields annotated as a
/// [Property].
Map<String, DeclarationMirror> propertyDeclarationsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (isRegularMethod(declaration) || isSetter(declaration)) return false;
    return declaration.metadata.any((d) => d is Property);
  });
}

// Set up the `properties` descriptor object.
Map _buildPropertiesObject(Type type) {
  var declarations = propertyDeclarationsFor(type);
  var properties = {};
  declarations.forEach((String name, DeclarationMirror declaration) {
    // Build a properties object for this property.
    properties[name] = _getPropertyInfoForType(type, declaration);
  });
  return properties;
}

/// All @Observe annotated methods.
Map<String, DeclarationMirror> _observeMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (!isRegularMethod(declaration)) return false;
    return declaration.metadata.any((d) => d is Observe);
  });
}

/// Set up the `observers` descriptor object, see
/// https://www.polymer-project.org/1.0/docs/devguide/properties.html#multi-property-observers
List _buildObserversObject(Type type) {
  var declarations = _observeMethodsFor(type);
  var observers = [];
  declarations.forEach((String name, DeclarationMirror declaration) {
    Observe observe = declaration.metadata.firstWhere((e) => e is Observe);
    // Build a properties object for this property.
    observers.add('$name(${observe.properties})');
  });
  return observers;
}

/// All @Listen annotated methods.
Map<String, DeclarationMirror> _listenMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (!isRegularMethod(declaration)) return false;
    return declaration.metadata.any((d) => d is Listen);
  });
}

/// Set up the `listeners` descriptor object, see
/// https://www.polymer-project.org/1.0/docs/devguide/events.html#event-listeners
Map _buildListenersObject(Type type) {
  var declarations = _listenMethodsFor(type);
  var listeners = {};
  declarations.forEach((String name, DeclarationMirror declaration) {
    for (Listen listen in declaration.metadata.where((e) => e is Listen)) {
      listeners[listen.eventName] = name;
    }
  });
  return listeners;
}

const _lifecycleMethods = const [
  'ready',
  'attached',
  'created',
  'detached',
  'attributeChanged',
];

const _serializeMethods = const ['serialize', 'deserialize'];

/// All lifecycle methods for a type.
Map<String, MethodMirror> _lifecycleMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (declaration is MethodMirror && declaration.isRegularMethod) {
      return _lifecycleMethods.contains(name) ||
          _serializeMethods.contains(name);
    }
    return false;
  });
}

/// Set up a proxy for the lifecyle methods, if they exists on the dart class.
/// If its a behavior we expect most of these
void _setupLifecycleMethods(Type type, JsObject prototype,
    [bool isBehavior = false]) {
  var declarations = _lifecycleMethodsFor(type);
  declarations.forEach((String name, MethodMirror declaration) {
    if (_lifecycleMethods.contains(name)) {
      if (!declaration.isStatic && isBehavior) {
        throw 'Lifecycle methods on behaviors must be static methods, found '
            '`$name` on `$type`. The first argument to these methods is the'
            'instance.';
      } else if (declaration.isStatic && !isBehavior) {
        throw 'Lifecycle methods on elements must not be static methods, found '
            '`$name` on class `$type`.';
      }
    }
    prototype[name] = _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, arguments) {
        var newArgs = [];
        var mirror;
        if (declaration.isStatic) {
          mirror = jsProxyReflectable.reflectType(type);
          newArgs.add(dartInstance);
        } else {
          mirror = jsProxyReflectable.reflect(dartInstance);
        }
        newArgs.addAll(arguments.map((arg) => convertToDart(arg)));
        return mirror.invoke(name, newArgs);
      }
    ]);
  });
}

/// All methods annotated with @reflectable.
Map<String, MethodMirror> _reflectableMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (declaration is MethodMirror && declaration.isRegularMethod) {
      return declaration.metadata.any((d) => d is PolymerReflectable);
    }
    return false;
  });
}

/// Set up a proxy for any method with an @reflectable annotation.
void _setupReflectableMethods(Type type, JsObject prototype) {
  var declarations = _reflectableMethodsFor(type);
  declarations.forEach((String name, MethodMirror declaration) {
    // Error on anything in `_registrationMethods`.
    if (_registrationMethods.contains(name)) {
      if (declaration.isStatic) return;
      throw 'Disallowed instance method `$name` with @reflectable annotation '
          'on the `${declaration.owner.simpleName}` class, since it has a '
          'special meaning in Polymer. You can either rename the method or'
          'change it to a static method. If it is a static method it will be '
          'invoked with the JS prototype of the element at registration time.';
    }

    // Add the method.
    addDeclarationToPrototype(name, type, declaration, prototype);
  });
}

/// All properties annotated with a [Reflectable] but not a [Property] since
/// those are handled separately.
Map<String, DeclarationMirror> _reflectablePropertiesFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, includeSuper: false,
      where: (name, declaration) {
    if (declaration is MethodMirror && declaration.isRegularMethod) {
      return false;
    }
    return declaration.metadata
        .any((d) => d is PolymerReflectable && d is! Property);
  });
}

/// Set up all @reflectable properties (that aren't marked with @property)
void _setupReflectableProperties(Type type, JsObject prototype) {
  var declarations = _reflectablePropertiesFor(type);
  declarations.forEach((name, declaration) =>
      addDeclarationToPrototype(name, type, declaration, prototype));
}

/// Add the hostAttributes property to the prototype if it exists.
void _setupHostAttributes(Type type, JsObject prototype) {
  var typeMirror = jsProxyReflectable.reflectType(type);
  var hostAttributes = readHostAttributes(typeMirror);
  if (hostAttributes != null) {
    prototype['hostAttributes'] = hostAttributes;
  }
}

final _registrationMethods = const ['registered', 'beforeRegister'];

/// Sets up any static methods contained in `_staticRegistrationMethods`.
void _setupRegistrationMethods(Type type, JsObject prototype) {
  var typeMirror = jsProxyReflectable.reflectType(type);
  for (String name in _registrationMethods) {
    var method = typeMirror.staticMembers[name];
    if (method == null || method is! MethodMirror) continue;
    prototype[name] = _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, arguments) {
        // Dartium hack, the proto has HtmlElement on its proto chain so
        // it thinks its an HtmlElement.
        if (dartInstance is HtmlElement) {
          dartInstance = new JsObject.fromBrowserObject(dartInstance);
        }

        var newArgs = [dartInstance]
          ..addAll(arguments.map((arg) => convertToDart(arg)));
        typeMirror.invoke(name, newArgs);
      }
    ]);
  }
}

/// Object that represents a property that was not found.
final _emptyPropertyInfo = {'defined': false};

/// Compute or return from cache information about `property` for `t`.
Map _getPropertyInfoForType(Type type, DeclarationMirror declaration) {
  assert(declaration is VariableMirror || declaration is MethodMirror);
  var jsPropertyType;
  var isFinal;
  var typeMirror;
  if (declaration is VariableMirror) {
    typeMirror = declaration.type;
    isFinal = declaration.isFinal;
  } else if (declaration is MethodMirror) {
    assert(declaration.isGetter);
    typeMirror = declaration.returnType;
    isFinal = !hasSetter(declaration);
  }
  if (typeMirror is ClassMirror && typeMirror.hasBestEffortReflectedType) {
    jsPropertyType = jsType(typeMirror.bestEffortReflectedType);
  }

  Property annotation = declaration.metadata.firstWhere((a) => a is Property);
  var property = {
    'defined': true,
    'notify': annotation.notify,
    'observer': annotation.observer,
    'reflectToAttribute': annotation.reflectToAttribute,
    'computed': annotation.computed,
    'value': _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, _) {
        var instanceMirror = jsProxyReflectable.reflect(dartInstance);
        var value =
            convertToJs(instanceMirror.invokeGetter(declaration.simpleName));
        if (value == null) return polymerDartUndefined;
        return value;
      }
    ]),
  };
  if (isFinal) {
    property['readOnly'] = true;
  }
  if (jsPropertyType != null) {
    property['type'] = jsPropertyType;
  }
  return property;
}

bool _isBehavior(instance) => instance is BehaviorAnnotation;
bool _hasBehaviorMeta(ClassMirror clazz) => clazz.metadata.any(_isBehavior);

/// List of [JsObjects]s representing the behaviors for an element.
JsArray<JsObject> _buildBehaviorsList(Type type) {
  // All behavior mixins, in order.
  var allBehaviors =
      mixinsFor(type, jsProxyReflectable).where(_hasBehaviorMeta);
  // The distilled list of behaviors.
  var behaviorStack = new List<ClassMirror>();

  // Verify behavior ordering and build up `behaviorStack`.
  for (var behavior in allBehaviors) {
    for (var interface in behavior.superinterfaces.reversed) {
      if (!_hasBehaviorMeta(interface)) continue;
      if (behaviorStack.isEmpty || behaviorStack.removeLast() != interface) {
        _throwInvalidMixinOrder(type, behavior);
      }
    }

    // Get the js object for the behavior from the annotation, and add it.
    behaviorStack.add(behavior);
  }

  return new JsArray<JsObject>.from([_polymerDart['InteropBehavior']]
    ..addAll(behaviorStack.map((ClassMirror behavior) {
      BehaviorAnnotation meta = behavior.metadata.firstWhere(_isBehavior);
      if (!behavior.hasBestEffortReflectedType) {
        throw 'Unable to get `bestEffortReflectedType` for behavior '
            '${behavior.simpleName}.';
      }
      return meta.getBehavior(behavior.bestEffortReflectedType);
    })));
}

// Throws an error about expected mixins that must precede the [clazz] mixin.
void _throwInvalidMixinOrder(Type type, ClassMirror mixin) {
  var expected = mixin.superinterfaces
      .where(_hasBehaviorMeta)
      .map((clazz) => clazz.simpleName)
      .join(', ');
  throw 'Unexpected mixin ordering on type $type. The ${mixin.simpleName} '
      'mixin must be  immediately preceded by the following mixins, in this '
      'order: $expected';
}

/// Given a [Type] return the [JsObject] representation of that type.
/// TODO(jakemac): Make this more robust, specifically around Lists.
dynamic jsType(Type type) {
  var typeString = '$type';
  if (typeString.startsWith('JsArray<')) typeString = 'List';
  if (typeString.startsWith('List<')) typeString = 'List';
  if (typeString.startsWith('Map<')) typeString = 'Map';
  switch (typeString) {
    case 'int':
    case 'double':
    case 'num':
      return context['Number'];
    case 'bool':
      return context['Boolean'];
    case 'List':
    case 'JsArray':
      return context['Array'];
    case 'DateTime':
      return context['Date'];
    case 'String':
      return context['String'];
    case 'Map':
    case 'JsObject':
      return context['Object'];
    default:
      // Just return the Dart type
      return type;
  }
}
