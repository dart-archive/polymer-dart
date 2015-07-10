// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_serialize;

import 'dart:convert';
import 'dart:js';

/// Mixin for Polymer serialization methods.
abstract class PolymerSerialize  {
  String serialize(Object value) {
    if ((value is Map) || (value is List)) {
      return JSON.encode(value);
    } else if (value is bool) {
      return value ? '' : null;
    }

    return value.toString();
  }

  Object deserialize(String value, dynamic type) {
    var ret;

    if (type == String) {
      ret = value;
    } else if (type == num) {
      try {
        ret = int.parse(value);
      } catch (e) {
        ret = double.parse(value);
      }
    } else if (type == DateTime) {
      var jsDate = new JsObject(context['Date'], [value]);
      ret = new DateTime.fromMillisecondsSinceEpoch(jsDate.callMethod('getTime'));
    } else if (type == bool) {
      ret = null != value && false != value;
    } else  {
      ret = JSON.decode(value);
    }
    return ret;
  }
}
