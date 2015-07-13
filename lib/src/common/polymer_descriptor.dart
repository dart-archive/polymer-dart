// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;
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
    'properties': buildPropertiesObject(type),
    'observers': _buildObserversObject(type),
    'listeners': _buildListenersObject(type),
    '__isPolymerDart__': true,
  };
  _setupLifecycleMethods(type, object);
  _setupEventHandlerMethods(type, object);

  return new JsObject.jsify(object);
}

/// Query options for finding properties on types.
final _propertyQueryOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement, withAnnotations: const [Property]);

/// Custom js object containing some helper methods for dart.
final JsObject _polymerDart = context['Polymer']['Dart'];

/// Returns a list of [smoke.Declaration]s for all fields annotated as a
/// [Property].
List<smoke.Declaration> propertyDeclarationsFor(Type type) =>
    smoke.query(type, _propertyQueryOptions);

// Set up the `properties` descriptor object.
Map buildPropertiesObject(Type type) {
  var declarations = propertyDeclarationsFor(type);
  var properties = {};
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      // Build a properties object for this property.
      properties[name] = _getPropertyInfoForType(type, declaration);
    }
  }
  return properties;
}

/// Query for the @Observe annotated methods.
final _observeMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    withAnnotations: const [Observe]);

/// Set up the `observers` descriptor object, see
/// https://www.polymer-project.org/1.0/docs/devguide/properties.html#multi-property-observers
List _buildObserversObject(Type type) {
  var declarations = smoke.query(type, _observeMethodOptions);
  var observers = [];
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    Observe observe = declaration.annotations.firstWhere((e) => e is Observe);
    // Build a properties object for this property.
    observers.add('$name(${observe.properties})');
  }
  return observers;
}

/// Query for the @Listen annotated methods.
final _listenMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    withAnnotations: const [Listen]);

/// Set up the `listeners` descriptor object, see
/// https://www.polymer-project.org/1.0/docs/devguide/events.html#event-listeners
Map _buildListenersObject(Type type) {
  var declarations = smoke.query(type, _listenMethodOptions);
  var listeners = {};
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    for (Listen listen in declaration.annotations.where((e) => e is Listen)) {
      listeners[listen.eventName] = name;
    }
  }
  return listeners;
}

/// Query for the lifecycle methods.
final _lifecycleMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    matches: (name) => [#ready, #attached, #detached, #attributeChanged, #serialize, #deserialize].contains(name));

/// Set up a proxy for the lifecyle methods, if they exists on the dart class.
void _setupLifecycleMethods(Type type, Map descriptor) {
  List<smoke.Declaration> results = smoke.query(type, _lifecycleMethodOptions);
  for (var result in results){
    descriptor[smoke.symbolToName(result.name)] = _polymerDart.callMethod(
        'invokeDartFactory',
        [
          (dartInstance, arguments) {
            var newArgs = arguments.map((arg) => dartValue(arg)).toList();
            return smoke.invoke(
                dartInstance, result.name, newArgs, adjust: true);
          }
        ]);
  }
}

/// Query for the [EventHandler] annotated methods.
final _eventHandlerMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    withAnnotations: const [EventHandler]);

/// Set up a proxy for any method with an @eventHandler annotation.
void _setupEventHandlerMethods(Type type, Map descriptor) {
  List<smoke.Declaration> results =
      smoke.query(type, _eventHandlerMethodOptions);
  for (var result in results){
    // TODO(jakemac): Support functions with more than 6 args? We should at
    // least throw a better error in that case.
    descriptor[smoke.symbolToName(result.name)] = _polymerDart.callMethod(
        'invokeDartFactory',
        [
          (dartInstance, arguments) {
            var newArgs = arguments.map((arg) => dartValue(arg)).toList();
            return smoke.invoke(
                dartInstance, result.name, newArgs, adjust: true);
          }
        ]);
  }
}

/// Object that represents a proeprty that was not found.
final _emptyPropertyInfo = new JsObject.jsify({'defined': false});

/// Compute or return from cache information about `property` for `t`.
Map _getPropertyInfoForType(Type type, smoke.Declaration declaration) {
  var jsTyped = jsType(declaration.type);
  if (jsTyped == null) return _emptyPropertyInfo;

  Property annotation =
      declaration.annotations.firstWhere((a) => a is Property);
  var property = {
    'type': jsTyped,
    'defined': true,
    'notify': annotation.notify,
    'observer': annotation.observer,
    'reflectToAttribute': annotation.reflectToAttribute,
    'computed': annotation.computed,
    'value': new JsFunction.withThis((dartInstance, [_]) {
      return jsValue(smoke.read(dartInstance, declaration.name));
    }),
  };
  if (declaration.isFinal) {
    property['readOnly'] = true;
  }
  return property;
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
