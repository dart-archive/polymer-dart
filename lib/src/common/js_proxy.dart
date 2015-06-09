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
          JsProxy dartInstance = jsObject['__dartClass__'];
          if (dartInstance.useCache) {
            return jsValue(jsObject['__cache__'][name]);
          } else {
            return jsValue(smoke.read(dartInstance, declaration.name));
          }
        }),
        'configurable': false,
      };
      if (!declaration.isFinal) {
        descriptor['set'] = new JsFunction.withThis((JsObject jsObject, value) {
          JsProxy dartInstance = jsObject['__dartClass__'];
          if (dartInstance.useCache) {
            jsObject['__cache__'][name] = jsValue(value);
          }
          if (value is JsObject) {
            var valueClass = value['__dartClass__'];
            if (valueClass != null) value = valueClass;
          }
          // TODO(jakemac): What about maps and lists on this side? JsArray
          // can probably be left alone since it implements list, but regular
          // JsObjects need to be wrapped in something that implements map.
          smoke.write(dartInstance, declaration.name, dartValue(value));
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
dynamic jsValue(dartValue) {
  if (dartValue is JsObject) {
    return dartValue;
  } else if (dartValue is JsProxy) {
    return dartValue.jsProxy;
  } else if (dartValue is Iterable) {
    var newList = new JsArray.from(dartValue.map((item) => jsValue(item)));
    newList['__dartList__'] = dartValue;
    return newList;
  } else if(dartValue is Map) {
    var newMap = new JsObject(context['Object']);
    dartValue.forEach((k, v) {
      newMap[k] = jsValue(v);
    });
    newMap['__dartMap__'] = dartValue;
    return newMap;
  }
  return dartValue;
}


/// Converts a js value to a dart value, unwrapping proxies as they are found.
dynamic dartValue(jsValue) {
  if (jsValue is JsArray) {
    var dartList = jsValue['__dartList__'];
    if (dartList != null) return dartList;
    dartList = jsValue.map((item) => dartValue(item)).toList();
    jsValue['__dartList__'] = dartList;
    return dartList;
  } else if (jsValue is JsObject) {
    var dartClass = jsValue['__dartClass__'];
    if (dartClass != null) return dartClass;
    dartClass = jsValue['__dartMap__'];
    if (dartClass != null) return dartClass;

    var dartMap = {};
    var keys = context['Object'].callMethod('keys', [jsValue]);
    for (var key in keys) {
      dartMap[key] = dartValue(jsValue[key]);
    }
    jsValue['__dartMap__'] = dartMap;
    return dartMap;
  }
  return jsValue;
}
