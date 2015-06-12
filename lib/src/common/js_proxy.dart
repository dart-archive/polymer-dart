// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.js_proxy;

import 'dart:js';
import 'dart:html';
import 'package:smoke/smoke.dart' as smoke;

// Mixin this class to get js proxy support!
abstract class JsProxy {
  /// Lazily create proxy constructors!
  static Map<Type, JsFunction> _jsProxyConstructors = {};
  bool useCache = false;

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

// Wraps an instance of a dart class in a js proxy.
JsObject _buildJsProxy(JsProxy instance) {
  var constructor = instance.jsProxyConstructor;
  var proxy = new JsObject(constructor);
  proxy['__dartClass__'] = instance;
  if (instance.useCache) {
    proxy['__cache__'] = new JsObject(context['Object']);
  }

  return proxy;
}

/// Query for all public fields/methods.
final _queryOptions = new smoke.QueryOptions(includeMethods: true, includeUpTo: HtmlElement);
final JsObject _polymerDart = context['Polymer']['Dart'];

/// Given a dart type, this creates a javascript constructor and prototype
/// which can act as a proxy for it.
JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = _polymerDart.callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  var declarations = smoke.query(dartType, _queryOptions);
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      var descriptor = {
        'get': _polymerDart.callMethod(
            'propertyAccessorFactory', [
              name,
              (dartInstance) {
                return jsValue(smoke.read(dartInstance, declaration.name));
              }
            ]),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = _polymerDart.callMethod(
          'propertySetterFactory', [
            name,
            (dartInstance, value) {
              smoke.write(dartInstance, declaration.name, dartValue(value));
            }
          ]
        );
      }
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod('defineProperty', [
        prototype,
        name,
        new JsObject.jsify(descriptor),
      ]);
    } else if (declaration.isMethod) {
      // TODO(jakemac): consolidate this code with the code in properties.dart.
      prototype[name] = _polymerDart.callMethod(
          'invokeDartFactory',
          [
            (dartInstance, arguments) {
              var newArgs = arguments.map((arg) => dartValue(arg)).toList();
              return smoke.invoke(
                  dartInstance, declaration.name, newArgs, adjust: true);
            }
          ]);
    }
  }

  constructor['prototype'] = prototype;
  return constructor;
}

/// Converts a dart value to a js value, using proxies when possible.
/// TODO(jakemac): Use expando to cache js arrays that mirror dart lists.
dynamic jsValue(dartValue) {
  if (dartValue is JsObject) {
    return dartValue;
  } else if (dartValue is JsProxy) {
    return dartValue.jsProxy;
  } else if (dartValue is Iterable) {
    var newList = new JsArray.from(dartValue.map((item) => jsValue(item)));
    newList['__dartClass__'] = dartValue;
    return newList;
  } else if(dartValue is Map) {
    var newMap = new JsObject(context['Object']);
    dartValue.forEach((k, v) {
      newMap[k] = jsValue(v);
    });
    newMap['__dartClass__'] = dartValue;
    return newMap;
  }
  return dartValue;
}


/// Converts a js value to a dart value, unwrapping proxies as they are found.
dynamic dartValue(jsValue) {
  if (jsValue is JsArray) {
    var dartList = jsValue['__dartClass__'];
    if (dartList != null) return dartList;
    dartList = jsValue.map((item) => dartValue(item)).toList();
    jsValue['__dartClass__'] = dartList;
    return dartList;
  } else if (jsValue is JsObject) {
    var dartClass = jsValue['__dartClass__'];
    if (dartClass != null) return dartClass;
    dartClass = jsValue['__dartClass__'];
    if (dartClass != null) return dartClass;

    var dartMap = {};
    var keys = context['Object'].callMethod('keys', [jsValue]);
    for (var key in keys) {
      dartMap[key] = dartValue(jsValue[key]);
    }
    jsValue['__dartClass__'] = dartMap;
    return dartMap;
  }
  return jsValue;
}
