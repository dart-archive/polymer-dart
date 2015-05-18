// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.dart.micro.properties;

import 'dart:html';
import 'package:smoke/smoke.dart' as smoke;

abstract class Properties implements Element {
  PropertyInfo getPropertyInfo(String propName) {
    var property = smoke.nameToSymbol(propName);
    if (property != null) {
      var decl = smoke.getDeclaration(runtimeType, property);
      if (decl == null || decl.isMethod || decl.isFinal) {
        _missingPropertyWarning(propName);
      } else {
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
}

