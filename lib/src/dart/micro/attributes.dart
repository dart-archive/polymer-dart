// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.dart.micro.attributes;

import 'dart:convert' show JSON;
import 'dart:html';
import 'dart:js';
import '../lib/case_map.dart';
import 'properties.dart';
import 'package:smoke/smoke.dart' as smoke;

abstract class Attributes implements Element, Properties {
  Map<String, dynamic> hostAttributes;
  bool _serializing = false;

  void marshalAttributes() => _takeAttributes();

  void installHostAttributes() {
    if (hostAttributes != null) _applyAttributes();
  }

  /* apply attributes to node but avoid overriding existing values */
  void _applyAttributes() {
    for (var n in hostAttributes.keys) {
      // NOTE: never allow 'class' to be set in hostAttributes
      // since shimming classes would make it work
      // inconsisently under native SD
      if (!attributes.containsKey(n) && n != 'class') {
        serializeValueToAttribute(hostAttributes[n], n);
      }
    }
  }

  void _takeAttributes() => _takeAttributesToModel();

  void _takeAttributesToModel() {
    for (var name in attributes.keys) {
      setAttributeToProperty(name);
    }
  }

  void setAttributeToProperty(attrName) {
    // Don't deserialize back to property if currently reflecting
    if (!_serializing) {
      // TODO(jakemac): Deal with PropertyEffects.
      var propName = dashToCamelCase(attrName);
      var info  = getPropertyInfo(propName);
      if (info != null) {
        var val = attributes[attrName];
        smoke.write(this, info.name, deserialize(val, info.type));
      }
    }
  }

  void reflectPropertyToAttribute(String name) {
    _serializing = true;
    var info = getPropertyInfo(name);
    if (info != null) {
      serializeValueToAttribute(
          smoke.read(this, info.name), camelToDashCase(name));
    }
    this._serializing = false;
  }

  void serializeValueToAttribute(value, String attribute, [Node node]) {
      var str = serialize(value);
      if (node == null) node = this;
      if (str == null) {
        attributes.remove(attribute);
      } else {
        attributes[attribute] = str;
      }
  }

  dynamic deserialize(String value, Type type) {
    var newValue;
    switch (type) {
      case int:
        newValue = int.parse(value);
        break;
      case double:
        newValue = double.parse(value);
        break;
      case num:
        newValue = num.parse(value);
        break;
      case bool:
        newValue = value != null;
        break;
      case Map:
        try {
          newValue = JSON.decode(value);
        } catch(x) {
          // allow non-JSON literals like Strings and Numbers
        }
        break;
      case List:
        try {
          newValue = JSON.decode(value);
        } catch(x) {
          newValue = null;
          window.console.warn(
              'Polymer::Attributes: couldn`t decode List as JSON: $value');
        }
        break;
      case DateTime:
        newValue = DateTime.parse(value);
        break;
      case String:
        newValue = value;
        break;
      default:
        _serializationWarning(value);
        break;
    }
    return newValue;
  }

  String serialize(dynamic value) {
    if (value is bool) return value ? '' : null;
    if (value is DateTime) return value.toString();
    if (value is List || value is Map) return JSON.encode(value);
    if (value is String) return value;
    if (value is num) return value.toString();
    _serializationWarning(value);
    return null;
  }

  void _serializationWarning(value) {
    window.console.warn('Unable to serialize/deserialize value: $value. \n'
        'Only num, bool, DateTime, List, Map, and String are supported.');
  }
}
