// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.js_proxy_builder;

import 'dart:js';
import 'package:smoke/smoke.dart';

final Map<Type, JsFunction> _proxyConstructors = {};

class JsProxy {
  JsObject _jsProxy;
  JsObject get jsProxy {
    if (_jsProxy == null) _jsProxy = _buildJsProxy(this);
    return _jsProxy;
  }
}

// Wraps an instance of a dart class in a js proxy.
JsObject _buildJsProxy(dynamic dartInstance) {
  var type = dartInstance.runtimeType;
  var constructor = _proxyConstructors.putIfAbsent(
      type, () => _buildJsConstructorForType(type));
  var proxy = new JsObject(constructor);
  proxy['__dartClass__'] = dartInstance;
  return proxy;
}

JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = context['Polymer']['Dart'].callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  // TODO(jakemac): consolidate this code with the code in properties.dart.
  var declarations = query(dartType, _queryOptions);
  for (var declaration in declarations) {
    var name = symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      var descriptor = {
        'get': new JsFunction.withThis((JsObject jsObject) {
          var val = read(jsObject['__dartClass__'], declaration.name);
          if (val is JsProxy) return val.jsProxy;
          if (val is Map || val is Iterable) return new JsObject.jsify(val);
          return val;
        }),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = new JsFunction.withThis((JsObject jsObject, value) {
          var valueClass = value['__dartClass__'];
          if (valueClass != null) value = valueClass;
          // TODO(jakemac): What about maps and lists on this side? JsArray
          // can probably be left alone since it implements list, but regular
          // JsObjects need to be wrapped in something that implements map.
          write(jsObject['__dartClass__'], declaration.name, value);
        });
      }
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod('defineProperty', [
        prototype,
        name,
        new JsObject.jsify(descriptor),
      ]);
    } else if (declaration.isMethod) {
      prototype[name] = new JsFunction.withThis((JsObject jsObject) {
        invoke(jsObject['__dartClass__'], declaration.name, []);
      });
    }
  }

  constructor['prototype'] = prototype;
  return constructor;
}

/// Query for all public fields/methods.
final _queryOptions = new QueryOptions(includeMethods: true);
