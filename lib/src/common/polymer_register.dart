// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_register;

import 'dart:js';
import 'package:web_components/web_components.dart' show CustomElementProxy;
import 'polymer_descriptor.dart';

class PolymerRegister extends CustomElementProxy {
  final Map<String, dynamic> hostAttributes;

  const PolymerRegister(String tagName,
      {String extendsTag, this.hostAttributes})
      : super(tagName, extendsTag: extendsTag);

  void initialize(Type type) {
    // Register the element via polymer js.
    context.callMethod('Polymer', [createPolymerDescriptor(type, this)]);
    // Register the dart type as a proxy.
    super.initialize(type);
  }
}
