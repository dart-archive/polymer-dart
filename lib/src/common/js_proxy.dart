// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.js_proxy;

import 'dart:html';
import 'dart:js';

import 'package:polymer_interop/polymer_interop.dart';
export 'package:polymer_interop/polymer_interop.dart'
    show convertToDart, convertToJs;
import 'package:reflectable/reflectable.dart';

import 'behavior.dart';
import 'declarations.dart';
import 'reflectable.dart';

/// Mixin this class to get js proxy support! If a [JsProxy] is passed to
/// [convertToJs] then you will get back a [JsObject] which is fully usable from
/// JS, but proxies all method calls and properties to the dart instance.
/// Calling [convertToDart] on that [JsObject] will also return the original
/// dart instance (not a copy).
@jsProxyReflectable
abstract class JsProxy implements JsProxyInterface {
  /// Lazily create proxy constructors!
  static Map<Type, JsFunction> _jsProxyConstructors = {};

  /// Whether to introduce a cache layer and make operations read from the
  ///  cache. By default JsProxys have no cache and the proxy reads values
  /// directly from the Dart object. This is primarily useful for objects that
  /// you pass in empty, and the javascript code will populate. It should be
  /// used carefully since its easy to get the two objects out of sync.
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
  setDartInstance(proxy, instance);
  if (instance.useCache) {
    proxy['__cache__'] = new JsObject(context['Object']);
  }

  return proxy;
}

const _knownMethodAndPropertyNames =
    'hostAttributes|created|attached|detached|attributeChanged|ready|serialize'
    '|deserialize|registered|beforeRegister';

/// The [Reflectable] class which gives you the ability to do everything that
/// PolymerElements and JsProxies need to do.
class JsProxyReflectable extends Reflectable {
  const JsProxyReflectable()
      : super.fromList(const [
          const InstanceInvokeMetaCapability(PolymerReflectable),
          const InstanceInvokeCapability(_knownMethodAndPropertyNames),
          metadataCapability,
          declarationsCapability,
          typeAnnotationQuantifyCapability,
          typeCapability,
          typeRelationsCapability,
          subtypeQuantifyCapability,
          const SuperclassQuantifyCapability(HtmlElement,
              excludeUpperBound: true),
          const StaticInvokeCapability(_knownMethodAndPropertyNames),
          const StaticInvokeMetaCapability(PolymerReflectable),
          correspondingSetterQuantifyCapability
        ]);
}

const jsProxyReflectable = const JsProxyReflectable();

final JsObject _polymerDart = context['Polymer']['Dart'];

/// Given a dart type, this creates a javascript constructor and prototype
/// which can act as a proxy for it.
JsFunction _buildJsConstructorForType(Type dartType) {
  var constructor = _polymerDart.callMethod('functionFactory');
  var prototype = new JsObject(context['Object']);

  var declarations =
      declarationsFor(dartType, jsProxyReflectable, where: (name, declaration) {
    // Skip declarations from [BehaviorProxy] classes. These should not
    // read/write from the dart class.
    return !declaration.owner.metadata.any((m) => m is BehaviorProxy);
  });
  declarations.forEach((name, declaration) =>
      addDeclarationToPrototype(name, dartType, declaration, prototype));

  constructor['prototype'] = prototype;
  return constructor;
}
