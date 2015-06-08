// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;
import '../common/js_object_model.dart';
import '../common/js_proxy.dart';
import '../common/property.dart';
import '../common/polymer_js_mixin.dart';
import '../common/event_handler.dart';

/// Query options for finding properties on types.
final _propertyQueryOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement, withAnnotations: const [Property]);

/// Returns a list of [smoke.Declaration]s for all fields annotated as a
/// [Property].
List<smoke.Declaration> propertyDeclarationsFor(Type type) =>
    smoke.query(type, _propertyQueryOptions);

///// Sets up getters and setters on an object to proxy back to the
///// dart class.
//JsObject buildPropertyDescriptorsFor(Type type) {
//  var declarations = propertyDeclarationsFor(type);
//  var jsObject = new JsObject(context['Object']);
//  for (var declaration in declarations) {
//    var name = smoke.symbolToName(declaration.name);
//    if (declaration.isField || declaration.isProperty) {
//      var descriptor = {
//        'get': new JsFunction.withThis((obj) {
//          if (obj is! PolymerJsMixin && obj is! JsProxy) {
//            obj = obj['__dartClass__'];
//          }
//          return jsValue(smoke.read(obj, declaration.name));
//        }),
//        'configurable': false,
//      };
//      if (!declaration.isFinal) {
//        descriptor['set'] = new JsFunction.withThis((obj, value) {
//          if (obj is! PolymerJsMixin && obj is! JsProxy) {
//            obj = obj['__dartClass__'];
//          }
//          smoke.write(obj, declaration.name, dartValue(value));
//        });
//      }
//      // Add a proxy getter/setter for this property.
//      context['Object'].callMethod('defineProperty', [
//        jsObject,
//        name,
//        new JsObject.jsify(descriptor),
//      ]);
//    };
//  };
//  return jsObject;
//}

// Set up the `properties` descriptor object.
JsObject buildPropertiesObject(Type type) {
  var declarations = propertyDeclarationsFor(type);
  var properties = {};
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      // Build a properties object for this property.
      properties[name] = _getPropertyInfoForType(type, declaration);
    }
  }
  return new JsObject.jsify(properties);
}

/// Query for the lifecycle methods.
final _lifecycleMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    matches: (name) => [#ready, #attached, #detached].contains(name));

/// Set up a proxy for the `ready`, `attached`, and `detached` methods, if they
/// exists on the dart class.
setupLifecycleMethods(Type type, JsObject prototype) {
  List<smoke.Declaration> results = smoke.query(type, _lifecycleMethodOptions);
  for (var result in results){
    prototype[smoke.symbolToName(result.name)] = new JsFunction.withThis((obj) {
      smoke.invoke(obj, result.name, []);
    });
  }
}

/// Query for the lifecycle methods.
final _eventHandlerMethodOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    withAnnotations: const [EventHandler]);

/// Set up a proxy for the `ready`, `attached`, and `detached` methods, if they
/// exists on the dart class.
setupEventHandlerMethods(Type type, JsObject prototype) {
  List<smoke.Declaration> results =
      smoke.query(type, _eventHandlerMethodOptions);
  for (var result in results){
    prototype[smoke.symbolToName(result.name)] =
        new JsFunction.withThis((obj, event, details) {
      smoke.invoke(obj, result.name, [event, details]);
    });
  }
}

/// Object that represents a proeprty that was not found.
final _emptyPropertyInfo = new JsObject.jsify({'defined': false});

/// Compute or return from cache information about `property` for `t`.
JsObject _getPropertyInfoForType(Type type, smoke.Declaration property) {
  var decl = smoke.getDeclaration(type, property.name);
  if (decl == null) return _emptyPropertyInfo;

  var jsType = _jsType(decl.type);
  if (jsType == null) return _emptyPropertyInfo;

  var annotation =
      decl.annotations.firstWhere((a) => a is Property) as Property;
  var properties = {
    'type': jsType,
    'defined': true,
    'notify': annotation.notify,
    'observer': annotation.observer,
  };
//  if (annotation.value != null) {
//    properties['value'] = annotation.value;
//  }
  if (property.isFinal) {
    properties['readOnly'] = true;
  }
  return new JsObject.jsify(properties);
}

/// Given a [Type] return the [JsObject] representation of that type.
JsObject _jsType(Type type) {
  switch ('$type') {
    case 'int':
    case 'double':
    case 'num':
      return context['Number'];
    case 'bool':
      return context['Boolean'];
    case 'List':
      return context['Array'];
    case 'DateTime':
      return context['DateTime'];
    case 'String':
      return context['String'];
    case 'Map':
    case 'JsObject':
    default:
      return context['Object'];
  }
}
