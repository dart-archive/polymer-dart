// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.micro.properties;

import 'dart:html';
import 'dart:js';
import 'package:smoke/smoke.dart' as smoke;
//import '../common/polymer_js_proxy.dart';

abstract class Properties implements /*PolymerJsDomProxy, */Element {
//  JsObject getPropertyInfo(String property) =>
//      (jsThis['getPropertyInfo'] as JsFunction).apply(
//          [property], thisArg: jsThis);

  PropertyInfo getPropertyInfo(String propName) {
    var property = smoke.nameToSymbol(propName);
    if (property != null) {
      var decl = smoke.getDeclaration(runtimeType, property);
      if (decl == null || decl.isMethod || decl.isFinal) {
        _missingPropertyWarning(propName);
      } else {
        // TODO(jakemac): Cache these (or codegen ahead of time).
        return new PropertyInfo(property, decl.type);
      }
    } else {
      _missingPropertyWarning(propName);
    }
    return null;
  }

  void _missingPropertyWarning(String attrName) {
    window.console.warn(
        'property for attribute $attrName of ${toString()} not found.');
  }
}

class PropertyInfo {
  Type type;
  Symbol name;
  PropertyInfo(this.name, this.type);

  operator ==(PropertyInfo other) {
    return other.type == type && other.name == name;
  }

  JsObject toJsObject() {
    return new JsObject.jsify({
      'type': _jsType(),
      'defined': true,
    });
  }

  JsObject _jsType() {
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
        throw 'Unrecognized type!';
    }
  }
}

