// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.js_proxy;

import 'dart:js';
import 'package:reflectable/reflectable.dart';
import 'declarations.dart';

// Mixin this class to get js proxy support!
abstract class JsProxy {
  /// Lazily create proxy constructors!
  static Map<Type, JsFunction> _jsProxyConstructors = {};

  /// Never reads from the dart object, instead reads properties from the
  /// `__cache__` object. This is primarily useful for objects that you pass in
  /// empty, and the javascript code will populate. It should be used carefully
  /// since its easy to get the two objects out of sync.
  bool useCache = false;

  /// The Javascript constructor that will be used to build proxy objects for
  /// this class.
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

/// Wraps an instance of a dart class in a js proxy.
JsObject _buildJsProxy(JsProxy instance) {
  var constructor = instance.jsProxyConstructor;
  var proxy = new JsObject(constructor);
  _addDartInstance(proxy, instance);
  if (instance.useCache) {
    proxy['__cache__'] = new JsObject(context['Object']);
  }

  return proxy;
}

class JsProxyReflectable extends Reflectable {
  const JsProxyReflectable()
      : super(instanceInvokeCapability, metadataCapability);
}
const jsProxyReflectable = const JsProxyReflectable();

final JsObject _polymerDart = context['Polymer']['Dart'];

/// Given a dart type, this creates a javascript constructor and prototype
/// which can act as a proxy for it.
JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = _polymerDart.callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  var declarations = declarationsFor(dartType, jsProxyReflectable);
  declarations.forEach((String name, DeclarationMirror declaration) {
    if (isProperty(declaration)) {
      var descriptor = {
        'get': _polymerDart.callMethod('propertyAccessorFactory', [
          name,
          (dartInstance) {
            var mirror = jsProxyReflectable.reflect(dartInstance);
            return jsValue(mirror.invokeGetter(name));
          }
        ]),
        'configurable': false,
      };
      if (!isFinal(declaration)) {
        descriptor['set'] = _polymerDart.callMethod('propertySetterFactory', [
          name,
          (dartInstance, value) {
            var mirror = jsProxyReflectable.reflect(dartInstance);
            mirror.invokeSetter(name, dartValue(value));
          }
        ]);
      }
      // Add a proxy getter/setter for this property.
      context['Object'].callMethod(
          'defineProperty', [prototype, name, new JsObject.jsify(descriptor),]);
    } else if (isRegularMethod(declaration)) {
      // TODO(jakemac): consolidate this code with the code in properties.dart.
      prototype[name] = _polymerDart.callMethod('invokeDartFactory', [
        (dartInstance, arguments) {
          var newArgs = arguments.map((arg) => dartValue(arg)).toList();
          var mirror = jsProxyReflectable.reflect(dartInstance);
          return mirror.invoke(name, newArgs);
        }
      ]);
    }
  });

  constructor['prototype'] = prototype;
  return constructor;
}

/// Converts a dart value to a js value, using proxies when possible.
/// TODO(jakemac): Use expando to cache js arrays that mirror dart lists?
dynamic jsValue(dartValue) {
  if (dartValue is JsObject) {
    return dartValue;
  } else if (dartValue is JsProxy) {
    return dartValue.jsProxy;
  } else if (dartValue is Iterable) {
    var newList = new JsArray.from(dartValue.map((item) => jsValue(item)));
    _addDartInstance(newList, dartValue);
    return newList;
  } else if (dartValue is Map) {
    var newMap = new JsObject(context['Object']);
    dartValue.forEach((k, v) {
      newMap[k] = jsValue(v);
    });
    _addDartInstance(newMap, dartValue);
    return newMap;
  } else if (dartValue is DateTime) {
    return new JsObject(context['Date'], [dartValue.millisecondsSinceEpoch]);
  }
  return dartValue;
}

/// Converts a js value to a dart value, unwrapping proxies as they are found.
dynamic dartValue(jsValue) {
  if (jsValue is JsArray) {
    var dartList = _getDartInstance(jsValue);
    if (dartList != null) return dartList;
    dartList = jsValue.map((item) => dartValue(item)).toList();
    _addDartInstance(jsValue, dartList);
    return dartList;
  } else if (jsValue is JsFunction) {
    var type = _dartType(jsValue);
    if (type != null) {
      return type;
    }
  } else if (jsValue is JsObject) {
    var dartClass = _getDartInstance(jsValue);
    if (dartClass != null) return dartClass;

    var constructor = jsValue['constructor'];
    if (constructor == context['Date']) {
      return new DateTime.fromMillisecondsSinceEpoch(
          jsValue.callMethod('getTime'));
    } else if (constructor == context['Object']) {
      var dartMap = {};
      var keys = context['Object'].callMethod('keys', [jsValue]);
      for (var key in keys) {
        dartMap[key] = dartValue(jsValue[key]);
      }
      _addDartInstance(jsValue, dartMap);
      return dartMap;
    }
  }
  return jsValue;
}

Type _dartType(JsFunction jsValue) {
  if (jsValue == context['String']) {
    return String;
  } else if (jsValue == context['Number']) {
    return num;
  } else if (jsValue == context['Boolean']) {
    return bool;
  } else if (jsValue == context['Array']) {
    return List;
  } else if (jsValue == context['Date']) {
    return DateTime;
  } else if (jsValue == context['Object']) {
    return Map;
  }
  // Unknown type
  return null;
}

/// Adds a reference to the original dart instance to a js proxy object.
void _addDartInstance(JsObject jsObject, dartInstance) {
  var details = new JsObject.jsify(
      {'configurable': false, 'enumerable': false, 'writeable': false,});
  // Don't want to jsify the instance, if its a map that will make turn it into
  // a JsObject.
  details['value'] = dartInstance;
  context['Object'].callMethod(
      'defineProperty', [jsObject, '__dartClass__', details]);
}

/// Gets a reference to the original dart instance from a js proxy object.
dynamic _getDartInstance(JsObject jsObject) => jsObject['__dartClass__'];
