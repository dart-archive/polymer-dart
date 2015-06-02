// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;
import '../common/js_object_model.dart';
import '../common/property.dart';

/// Add proxies for the fields/properties from [Type] to the `prototype`.
void setupPrototype(Type type, JsObject prototype) {
  setupProperties(type, prototype);
  setupReady(type, prototype);
}

/// Query options for finding properties on types.
final _propertyQueryOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement, withAnnotations: const [Property]);

/// Initialize properties for a given dart type and js prototype.
void setupProperties(Type type, JsObject prototype) {
  List<smoke.Declaration> results = smoke.query(type, _propertyQueryOptions);
  setupPropertyDescriptors(results, prototype['__data__']);
  setupPropertiesObject(type, results, prototype);
}

/// Sets up getters and setters on the `__data__` object to proxy back to the
/// dart class.
void setupPropertyDescriptors(
    List<smoke.Declaration> declarations, JsObject jsObject) {
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      var descriptor = {
        'get': new JsFunction.withThis((obj) {
          if (obj is! HtmlElement) obj = obj['__proxy__'];
          var val = smoke.read(obj, declaration.name);
          if (val is Map || val is Iterable) return new JsObject.jsify(val);
          return val;
        }),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = new JsFunction.withThis((obj, value) {
          smoke.write(obj['__proxy__'], declaration.name, value);
        });
      }
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod('defineProperty', [
        jsObject,
        name,
        new JsObject.jsify(descriptor),
      ]);
    };
  };
}

// Set up the `properties` descriptor object.
void setupPropertiesObject(
    Type type, List<smoke.Declaration> declarations, JsObject jsObject) {
  var properties = {};
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      // Build a properties object for this property.
      properties[name] = _getPropertyInfoForType(type, declaration);
    }
  }
  if (properties.isNotEmpty) {
    jsObject['properties'] = new JsObject.jsify(properties);
  }
}

/// Query for the ready method.
final _readyQueryOptions = new smoke.QueryOptions(
    includeUpTo: HtmlElement,
    includeMethods: true,
    includeProperties: false,
    includeFields: false,
    matches: (name) => name == #ready);

/// Set up a proxy for the `ready` method, if one exists on the dart class.
setupReady(Type type, JsObject prototype) {
  List<smoke.Declaration> results = smoke.query(type, _readyQueryOptions);
  if (results.isEmpty) return;
  prototype['ready'] = new JsFunction.withThis((obj) {
    smoke.invoke(obj['__proxy__'], #ready, []);
  });
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
