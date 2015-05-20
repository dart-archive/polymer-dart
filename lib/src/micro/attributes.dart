// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.attributes;

import 'dart:html';
import 'dart:js';
import 'properties.dart';

final _polymerBase = context['Polymer']['Base'];

abstract class Attributes implements Element, Properties {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) _jsThis = new JsObject.fromBrowserObject(this);
    return _jsThis;
  }

  JsObject _jsProxy;
  JsObject get jsProxy {
    if (_jsProxy == null) {
      _jsProxy = new JsObject.jsify({
        '_applyAttributes': (node, attributes) {
          (_polymerBase['_applyAttributes'] as JsFunction).apply(
              [jsThis, attributes], thisArg: jsProxy);
        },
        'hasAttribute': (attribute) {
          return attributes.containsKey(attribute);
        },
        'serializeValueToAttribute': (value, attribute, _) {
          return (_polymerBase['serializeValueToAttribute'] as JsFunction)
              .apply([value, attribute, jsThis], thisArg: jsProxy);
        },
        'serialize': (value) {
          return (_polymerBase['serialize'] as JsFunction).apply(
              [value], thisArg: jsProxy);
        },
      });
    }
    return _jsProxy;
  }

  void installHostAttributes(Map<String, dynamic> hostAttributes) {
    (_polymerBase['_installHostAttributes'] as JsFunction).apply(
        [new JsObject.jsify(hostAttributes)], thisArg: jsProxy);
  }

//  void marshalAttributes() => _takeAttributes();
//
//  void _takeAttributes() => _takeAttributesToModel();
//
//  void _takeAttributesToModel() {
//    for (var name in attributes.keys) {
//      setAttributeToProperty(name);
//    }
//  }
//
//  void setAttributeToProperty(attrName) {
//    // Don't deserialize back to property if currently reflecting
//    if (!_serializing) {
//      // TODO(jakemac): Deal with PropertyEffects.
//      var propName = PolymerJs.dashToCamelCase(attrName);
//      var info  = getPropertyInfo(propName);
//      if (info != null) {
//        var val = attributes[attrName];
//        smoke.write(this, info.name, deserialize(val, info.type));
//      }
//    }
//  }
//
//  void reflectPropertyToAttribute(String name) {
//    _serializing = true;
//    var info = getPropertyInfo(name);
//    if (info != null) {
//      serializeValueToAttribute(
//          smoke.read(this, info.name), PolymerJs.camelToDashCase(name));
//    }
//    this._serializing = false;
//  }
//
//  dynamic deserialize(String value, Type type) {
//    var newValue;
//    switch (type) {
//      case int:
//        newValue = int.parse(value);
//        break;
//      case double:
//        newValue = double.parse(value);
//        break;
//      case num:
//        newValue = num.parse(value);
//        break;
//      case bool:
//        newValue = value != null;
//        break;
//      case Map:
//        try {
//          newValue = JSON.decode(value);
//        } catch(x) {
//          // allow non-JSON literals like Strings and Numbers
//        }
//        break;
//      case List:
//        try {
//          newValue = JSON.decode(value);
//        } catch(x) {
//          newValue = null;
//          window.console.warn(
//              'Polymer::Attributes: couldn`t decode List as JSON: $value');
//        }
//        break;
//      case DateTime:
//        newValue = DateTime.parse(value);
//        break;
//      case String:
//        newValue = value;
//        break;
//      default:
//        _serializationWarning(value);
//        break;
//    }
//    return newValue;
//  }
}
