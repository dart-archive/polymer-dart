// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;

abstract class Properties implements Element {

  PropertyInfo getPropertyInfo(String propName) {
    var property = smoke.nameToSymbol(propName);
    if (property != null) {
      var decl = smoke.getDeclaration(runtimeType, property);
      if (decl != null) {
        // TODO(jakemac): Cache these (or codegen ahead of time).
        return new PropertyInfo(property, decl.type);
      }
    }
    return null;
  }
}

class PropertyInfo {
  final Type type;
  final Symbol name;
  PropertyInfo(this.name, this.type);

  operator ==(PropertyInfo other) {
    return other.type == type && other.name == name;
  }

  static JsObject toJsObject(PropertyInfo info) {
    if (info == null) return new JsObject.jsify({'defined': false});
    return new JsObject.jsify({
      'type': _jsType(info.type),
      'defined': true,
    });
  }

  static JsObject _jsType(Type type) {
    switch (type) {
      case int:
      case double:
      case num:
        return context['Number'];
      case bool:
        return context['Boolean'];
      case Map:
        return context['Object'];
      case List:
        return context['Array'];
      case DateTime:
        return context['DateTime'];
      case String:
        return context['String'];
      default:
        window.console.warn('Unable to convert `$type` to a javascript type.');
    }
  }
}

