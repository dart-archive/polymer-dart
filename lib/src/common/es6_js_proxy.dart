// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of polymer.lib.src.common.js_proxy;

/// Mixin this class to get js proxy support! If a [JsProxy] is passed to
/// [convertToJs] then you will get back a [JsObject] which is fully usable from
/// JS, but proxies all method calls and properties to the dart instance.
/// Calling [convertToDart] on that [JsObject] will also return the original
/// dart instance (not a copy).
///
/// *WARNING* EXPERIMENTAL FEATURE USING ES6 PROXY
/// *WARNING* BROWSER COMPATIBILITY ISSUES (IE / SAFARI DO NOT SUPPORT ES6 PROXY YET)
@jsProxyReflectable
abstract class ES6JsProxy implements JsProxyInterface {
  JsFunction get jsProxyConstructor =>
      throw new UnsupportedError("not supported for ES6JsProxy");
  JsObject _jsProxy;
  JsObject get jsProxy {
    if (_jsProxy == null) _jsProxy = _buildES6JsProxy(this);
    return _jsProxy;
  }
}

/// Wraps an instance of a dart class in a js proxy.
JsObject _buildES6JsProxy(JsProxyInterface instance) {
  return _createES6JsProxy.apply([instance]);
}

final JsObject _polymerDartES6 = context['Polymer']['Dart']['ES6'];

final JsFunction _createES6JsProxy = _polymerDartES6['createES6JsProxy'];

final JsFunction _createMethodInvoker = _polymerDartES6['createMethodInvoker'];

final JsObject _Unsupported = _polymerDartES6['Unsupported'];

/// Hooks for ES6 Proxies
///
/// Hooks for getting and setting properties and methods from and to dart objects.
///
initES6Proxy() {
  <String, Function>{
    '_dartGetter': (dartInstance, propertyName) {
      InstanceMirror instanceMirror = jsProxyReflectable.reflect(dartInstance);

      Map<String, DeclarationMirror> declarations = declarationsFor(
          dartInstance.runtimeType, jsProxyReflectable,
          includeSuper: false,
          where: (String name, DeclarationMirror m) =>
              name == propertyName &&
              (isProperty(m) || (m is MethodMirror && m.isRegularMethod)));
      DeclarationMirror decl = declarations[propertyName];

      if (decl == null) {
        return _Unsupported;
      }

      // TODO(dam0vm3nt): support for static
      if (isProperty(decl)) {
        return convertToJs(instanceMirror.invokeGetter(propertyName));
      } else if (decl is MethodMirror) {
        // Should we use an ES6 proxy here to proxy function calls ?
        // Should we use a cache for method invokers ?
        return _createMethodInvoker.apply([
          (List args) => convertToJs(instanceMirror.invoke(
              propertyName, args.map((x) => convertToDart(x)).toList()))
        ]);
      } else {
        throw new UnsupportedError("Don't know how to handle ${decl}");
      }
    },
    '_dartGetProperties': (dartInstance) {
      Map<String, DeclarationMirror> props = declarationsFor(
          dartInstance.runtimeType, jsProxyReflectable,
          includeSuper: false,
          where: (String name, DeclarationMirror m) =>
              (isProperty(m) && !isSetter(m)) ||
              (m is MethodMirror && m.isRegularMethod));

      Map<String, DeclarationMirror> mets = declarationsFor(
          dartInstance.runtimeType, jsProxyReflectable,
          includeSuper: false,
          where: (String name, DeclarationMirror m) =>
              (isProperty(m) && !isSetter(m)) ||
              (m is MethodMirror && m.isRegularMethod));
      return new JsObject.jsify({
        "props": new JsArray.from(props.keys),
        "mets": new JsArray.from(mets.keys)
      });
    },
    '_dartSetter': (dartInstance, propertyName, value) {
      InstanceMirror instanceMirror = jsProxyReflectable.reflect(dartInstance);
      Map<String, DeclarationMirror> declarations = declarationsFor(
          dartInstance.runtimeType, jsProxyReflectable,
          includeSuper: false,
          where: (String name, DeclarationMirror decl) =>
              (name == propertyName &&
                  (decl is VariableMirror) &&
                  (!decl.isFinal)) ||
              (name == "${propertyName}=" && (decl is MethodMirror)));

      if (declarations.isEmpty) {
        return _Unsupported;
      }

      // TODO(dam0vm3nt): support for static

      instanceMirror.invokeSetter(propertyName, convertToDart(value));
    }
  }.forEach((String k, Function fun) {
    _polymerDartES6[k] = fun;
  });
}
