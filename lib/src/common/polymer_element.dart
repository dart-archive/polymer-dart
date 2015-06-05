// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_element;

import 'dart:js';
import 'dart:html';
import 'package:initialize/initialize.dart' show Initializer;
import 'package:web_components/web_components.dart' show CustomElementProxy;
import 'polymer_js_mixin.dart';
import '../micro/properties.dart';

class PolymerElement extends CustomElementProxy {
  final Map<String, dynamic> hostAttributes;

  const PolymerElement(
      String tagName, {String extendsTag, this.hostAttributes})
      : super(tagName, extendsTag: extendsTag);

  void initialize(Type type) {
    var polymerObject = _createPolymerObject(type, this);
    var constructor = context['Polymer'].callMethod('Class', [polymerObject]);
    var prototype = constructor['prototype'];
    // TODO(jakemac): Remove this hack once we fix
    // https://github.com/dart-lang/sdk/issues/23574
    if (prototype is! JsObject) {
      prototype = new JsObject.fromBrowserObject(prototype);
    }
    prototype['__isPolymerDart__'] = true;
    prototype['__data__'] = buildPropertyDescriptorsFor(type);
    setupLifecycleMethods(type, prototype);
    setupEventHandlerMethods(type, prototype);

    // Register the prototype via js interop!
    new JsObject.fromBrowserObject(document).callMethod('registerElement', [
      tagName,
      new JsObject.jsify({
        'prototype': prototype,
        'extends': extendsTag,
      })
    ]);

    super.initialize(type);
  }
}

JsObject _createPolymerObject(Type type, PolymerElement element) {
  var object = {
    'is': element.tagName,
    'extends': element.extendsTag,
    'hostAttributes': element.hostAttributes,
    'properties': buildPropertiesObject(type),
  };
  return new JsObject.jsify(object);
}
