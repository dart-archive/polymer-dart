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
  return proxy;
}

/// Query for all public fields/methods.
final _queryOptions = new smoke.QueryOptions(includeMethods: true, includeUpTo: HtmlElement);

/// Given a dart type, this creates a javascript constructor and prototype
/// which can act as a proxy for it.
JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = context['Polymer']['Dart'].callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  // TODO(jakemac): consolidate this code with the code in properties.dart.
  var declarations = smoke.query(dartType, _queryOptions);
  for (var declaration in declarations) {
    var name = smoke.symbolToName(declaration.name);
    if (declaration.isField || declaration.isProperty) {
      var descriptor = {
        'get': new JsFunction.withThis((JsObject jsObject) {
          var val = smoke.read(jsObject['__dartClass__'], declaration.name);
          return jsValue(val);
        }),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = new JsFunction.withThis((JsObject jsObject, value) {
          if (value is JsObject) {
            var valueClass = value['__dartClass__'];
            if (valueClass != null) value = valueClass;
          }
          // TODO(jakemac): What about maps and lists on this side? JsArray
          // can probably be left alone since it implements list, but regular
          // JsObjects need to be wrapped in something that implements map.
          smoke.write(jsObject['__dartClass__'], declaration.name, dartValue(value));
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
        smoke.invoke(jsObject['__dartClass__'], declaration.name, []);
      });
    }
  }

  constructor['prototype'] = prototype;
  return constructor;
}

/// Converts a dart value to a js value, using proxies when possible.
dynamic jsValue(value) {
  if (value is JsProxy) {
    return value.jsProxy;
  } else if (value is Iterable) {
    return new JsArray.from(value.map((item) => jsValue(item)));
  } else if(value is Map) {
    var newValue = new JsObject(context['Object']);
    value.forEach((k, v) {
      newValue[k] = jsValue(v);
    });
    return newValue;
  }
  return value;
}


/// Converts a js value to a dart value, unwrapping proxies as they are found.
dynamic dartValue(value) {
  if (value is JsArray) {
    value = value.map((item) {
      var itemProxy = (item is JsObject)  ? item['__dartClass__'] : null;
      if (itemProxy != null) item = itemProxy;
      return item;
    }).toList();
  } else {
    var valueProxy = (value is JsObject)  ? value['__dartClass__'] : null;
    if (valueProxy != null) value = valueProxy;
  }
  return value;
}
