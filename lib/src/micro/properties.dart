// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;

/// Query options for finding properties on types.
final _defaultQueryOptions = new smoke.QueryOptions(includeUpTo: HtmlElement);

/// Add proxies for the fields/properties from [Type] to the `prototype`.
void setupProperties(Type type, JsObject prototype) {
  var properties = {};
  List<smoke.Declaration> results = smoke.query(type, _defaultQueryOptions);
  for (var result in results) {
    var name = smoke.symbolToName(result.name);
    if (prototype[name] != null) continue;
    if (result.isField || result.isProperty) {
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod('defineProperty', [
        prototype['__data__'],
        name,
        new JsObject.jsify({
          'get': new JsFunction.withThis((obj) {
            return smoke.read(obj['__proxy__'], result.name);
          }),
          'set': new JsFunction.withThis((obj, value) {
            smoke.write(obj['__proxy__'], result.name, value);
          }),
          'configurable': false,
        }),
      ]);
      // Build a properties object for this property.
      properties[name] = _getPropertyInfoForType(type, name);
    }
  }
  if (properties.isNotEmpty) {
    prototype['properties'] = new JsObject.jsify(properties);
  }
}

/// Object that represents a proeprty that was not found.
final _emptyPropertyInfo = new JsObject.jsify({'defined': false});

/// Compute or return from cache information about `property` for `t`.
JsObject _getPropertyInfoForType(Type type, String propName) {
  var property = smoke.nameToSymbol(propName);
  if (property == null) return _emptyPropertyInfo;

  var decl = smoke.getDeclaration(type, property);
  if (decl == null) return _emptyPropertyInfo;

  var jsType = _jsType(decl.type);
  if (jsType == null) return _emptyPropertyInfo;

  return new JsObject.jsify({
    'type': jsType,
    'defined': true,
  });
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
    case 'Map':
    case 'JsObject':
      return context['Object'];
    case 'List':
      return context['Array'];
    case 'DateTime':
      return context['DateTime'];
    case 'String':
      return context['String'];
    default:
      window.console.warn('Unable to convert `$type` to a javascript type.');
  }
}
