// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:js';
import 'package:reflectable/reflectable.dart';
import 'behavior.dart';
import 'declarations.dart';
import 'js_proxy.dart';
import 'property.dart';
import 'event_handler.dart';
import 'listen.dart';
import 'observe.dart';
import 'polymer_register.dart';

/// Creates a javascript object which can be passed to polymer js to register
/// an element, given a dart [Type] and a [PolymerRegister] annotation.
JsObject createPolymerDescriptor(Type type, PolymerRegister annotation) {
  var object = {
    'is': annotation.tagName,
    'extends': annotation.extendsTag,
    'hostAttributes': annotation.hostAttributes,
    'properties': _buildPropertiesObject(type),
    'observers': _buildObserversObject(type),
    'listeners': _buildListenersObject(type),
    'behaviors': _buildBehaviorsList(type),
    '__isPolymerDart__': true,
  };
  _setupLifecycleMethods(type, object);
  _setupEventHandlerMethods(type, object);

  return new JsObject.jsify(object);
}

/// Custom js object containing some helper methods for dart.
final JsObject _polymerDart = context['Polymer']['Dart'];

/// Returns a list of [DeclarationMirror]s for all fields annotated as a
/// [Property].
Map<String, DeclarationMirror> propertyDeclarationsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, where: (name, declaration) {
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
  return declarationsFor(type, jsProxyReflectable, where: (name, declaration) {
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
  return declarationsFor(type, jsProxyReflectable, where: (name, declaration) {
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
  'detached',
  'attributeChanged',
  'serialize',
  'deserialize'
];

/// All lifecycle methods for a type.
Map<String, DeclarationMirror> _lifecycleMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, where: (name, declaration) {
    if (!isRegularMethod(declaration)) return false;
    return _lifecycleMethods.contains(name);
  });
}

/// Set up a proxy for the lifecyle methods, if they exists on the dart class.
void _setupLifecycleMethods(Type type, Map descriptor) {
  var declarations = _lifecycleMethodsFor(type);
  declarations.forEach((String name, DeclarationMirror declaration) {
    descriptor[name] = _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, arguments) {
        var newArgs = arguments.map((arg) => dartValue(arg)).toList();
        var instanceMirror = jsProxyReflectable.reflect(dartInstance);
        return instanceMirror.invoke(name, newArgs);
      }
    ]);
  });
}

/// All methods annotated with @eventHandler.
Map<String, DeclarationMirror> _eventHandlerMethodsFor(Type type) {
  return declarationsFor(type, jsProxyReflectable, where: (name, declaration) {
    if (!isRegularMethod(declaration)) return false;
    return declaration.metadata.any((d) => d is EventHandler);
  });
}

/// Set up a proxy for any method with an @eventHandler annotation.
void _setupEventHandlerMethods(Type type, Map descriptor) {
  var declarations = _eventHandlerMethodsFor(type);
  declarations.forEach((String name, DeclarationMirror declaration) {
    // TODO(jakemac): Support functions with more than 6 args? We should at
    // least throw a better error in that case.
    descriptor[name] = _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, arguments) {
        var newArgs = arguments.map((arg) => dartValue(arg)).toList();
        var instanceMirror = jsProxyReflectable.reflect(dartInstance);
        return instanceMirror.invoke(name, newArgs);
      }
    ]);
  });
}

/// Object that represents a proeprty that was not found.
final _emptyPropertyInfo = new JsObject.jsify({'defined': false});

/// Compute or return from cache information about `property` for `t`.
Map _getPropertyInfoForType(Type type, DeclarationMirror declaration) {
  assert(declaration is VariableMirror || declaration is MethodMirror);
  var propertyType;
  var isFinal;
  if (declaration is VariableMirror) {
    propertyType = declaration.type.reflectedType;
    isFinal = declaration.isFinal;
  } else if (declaration is MethodMirror) {
    assert(declaration.isGetter);
    propertyType = declaration.returnType.reflectedType;
    isFinal = !hasSetter(declaration);
  }
  var jsTyped = jsType(propertyType);
  if (jsTyped == null) return _emptyPropertyInfo;

  Property annotation = declaration.metadata.firstWhere((a) => a is Property);
  var property = {
    'type': jsTyped,
    'defined': true,
    'notify': annotation.notify,
    'observer': annotation.observer,
    'reflectToAttribute': annotation.reflectToAttribute,
    'computed': annotation.computed,
    'value': new JsFunction.withThis((dartInstance, [_]) {
      var instanceMirror = jsProxyReflectable.reflect(dartInstance);
      return jsValue(instanceMirror.invokeGetter(declaration.simpleName));
    }),
  };
  if (isFinal) {
    property['readOnly'] = true;
  }
  return property;
}

bool _isBehavior(instance) => instance is BehaviorAnnotation;
bool _hasBehaviorMeta(ClassMirror clazz) => clazz.metadata.any(_isBehavior);

/// List of [JsObjects]s representing the behaviors for an element.
Iterable<JsObject> _buildBehaviorsList(Type type) {
  // All behavior mixins, in order.
  var allBehaviors =
      mixinsFor(type, jsProxyReflectable).where(_hasBehaviorMeta);
  // The distilled list of behaviors.
  var finalBehaviors = new List<ClassMirror>();

  // Verify behavior odering and build up `finalBehaviors`.
  for (var behavior in allBehaviors) {
    void checkAndRemoveSuperInterfaces(ClassMirror clazz) {
      clazz.superinterfaces.reversed.where(_hasBehaviorMeta).forEach((interface) {
        if (finalBehaviors.isEmpty) {
          _throwInvalidMixinOrder(type, clazz);
        }
        var previous = finalBehaviors.removeLast();
        if (previous != interface) {
          _throwInvalidMixinOrder(type, clazz);
        }
      });
    }
    checkAndRemoveSuperInterfaces(behavior);

    // Get the js object for the behavior from the annotation, and add it.
    finalBehaviors.add(behavior);
  }

  return finalBehaviors.map((ClassMirror behavior) {
    BehaviorAnnotation meta = behavior.metadata.firstWhere(_isBehavior);
    return meta.getBehavior(behavior.reflectedType);
  });
}

// Throws an error about expected mixins that must precede the [clazz] mixin.
void _throwInvalidMixinOrder(Type type, ClassMirror mixin) {
  var expected = mixin.superinterfaces.where(_hasBehaviorMeta)
      .map((clazz) => clazz.simpleName).join(', ');
  throw 'Unexpected mixin ordering on type $type. The ${mixin.simpleName} mixin '
     'must be  immediately preceded by the following mixins, in this order: '
     '$expected';
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
