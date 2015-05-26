// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;

/// Cache of information about properties for each type.
final Map<Type, Map<Symbol, JsObject>> _propertyInfoByType = {};

/// Object that represents a proeprty that was not found.
final _emptyPropertyInfo = new JsObject.jsify({'defined': false});

/// Compute or return from cache information about `property` for `t`.
JsObject getPropertyInfoForType(Type t, String propName) {
  _propertyInfoByType.putIfAbsent(t, () => {});
  var property = smoke.nameToSymbol(propName);
  if (property != null) {
    return _propertyInfoByType[t].putIfAbsent(property, () {
      var decl = smoke.getDeclaration(t, property);
      if (decl == null) return _emptyPropertyInfo;
      return new JsObject.jsify({
        'type': _jsType(decl.type),
        'defined': true,
      });
    });
  }
  return _emptyPropertyInfo;
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

/// Query options for finding properties on types.
final _defaultQueryOptions = new smoke.QueryOptions(includeUpTo: HtmlElement);

/// Add proxies for the fields/properties from [Type] to the `prototype`.
void addPropertyProxies(Type type, JsObject prototype) {
  List<smoke.Declaration> results = smoke.query(type, _defaultQueryOptions);
  for (var result in results) {
    var name = smoke.symbolToName(result.name);
    if (prototype[name] != null) continue;
    if (result.isField || result.isProperty) {
      // Extra proxies for this element!
      context['Object'].callMethod('defineProperty', [
        prototype,
        name,
        new JsObject.jsify({
          'get': new JsFunction.withThis(
              (obj) => smoke.read(obj['__proxy__'], result.name)),
          'set': new JsFunction.withThis((obj, value) =>
              smoke.write(obj['__proxy__'], result.name, value)),
        }),
      ]);
    }
  }
  context['$type'] = prototype;
}
