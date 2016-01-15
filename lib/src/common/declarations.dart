// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.declarations;

import 'dart:js';

import 'package:reflectable/reflectable.dart';

import '../../polymer_micro.dart';

final JsObject _polymerDart = context['Polymer']['Dart'];

List<ClassMirror> mixinsFor(Type type, Reflectable reflectionClass,
    {bool where(ClassMirror mirror)}) {
  var typeMirror = reflectionClass.reflectType(type);
  var mixins = [];
  var superClass = _getSuper(typeMirror);
  while (superClass != null && !_isPolymerMixin(superClass.mixin)) {
    var mixin = superClass.mixin;
    if (mixin != superClass && (where == null || where(mixin))) {
      mixins.add(mixin);
    }
    superClass = _getSuper(superClass);
  }
  return mixins.reversed.toList();
}

/// Retrieves all the declarations for a class, given a [Reflectable] instance.
/// If a [_WhereFn] is supplied then it only returns the declarations which
/// return true from that.
Map<String, DeclarationMirror> declarationsFor(
    Type type, Reflectable reflectionClass,
    {bool where(String name, DeclarationMirror declaration),
    bool includeSuper: true}) {
  var typeMirror = reflectionClass.reflectType(type);
  var declarations = {};
  var superClass = typeMirror;
  while (superClass != null && !_isPolymerMixin(superClass.mixin)) {
    superClass.declarations.forEach((name, declaration) {
      if (declarations.containsKey(name)) return;
      if (where != null && !where(name, declaration)) return;
      declarations[name] = declaration;
    });
    superClass = includeSuper ? _getSuper(superClass) : null;
  }
  return declarations;
}

bool _isPolymerMixin(ClassMirror clazz) {
  return clazz.hasReflectedType &&
      (clazz.reflectedType == PolymerMixin ||
          clazz.reflectedType == PolymerBase);
}

ClassMirror _getSuper(ClassMirror clazz) {
  // Currently throws post-transform if superclass isn't annotated with a
  // [Reflectable] class.
  try {
    return clazz.superclass;
  } catch (e) {
    return null;
  }
}

bool isFinal(DeclarationMirror declaration) {
  if (declaration is VariableMirror) return declaration.isFinal;
  if (declaration is MethodMirror && declaration.isGetter) {
    return !hasSetter(declaration);
  }
  return false;
}

bool isProperty(DeclarationMirror declaration) {
  if (declaration is VariableMirror) return true;
  if (declaration is MethodMirror) return !declaration.isRegularMethod;
  return false;
}

bool isRegularMethod(DeclarationMirror declaration) {
  return declaration is MethodMirror &&
      !declaration.isStatic &&
      declaration.isRegularMethod;
}

bool isSetter(DeclarationMirror declaration) {
  return declaration is MethodMirror && declaration.isSetter;
}

bool hasSetter(MethodMirror getterDeclaration) {
  assert(getterDeclaration.isGetter);
  var owner = getterDeclaration.owner;
  assert(owner is LibraryMirror || owner is ClassMirror);
  return owner.declarations.containsKey('${getterDeclaration.simpleName}=');
}

void addDeclarationToPrototype(
    String name, Type type, DeclarationMirror declaration, JsObject prototype) {
  if (isProperty(declaration)) {
    var descriptor = {
      'get': _polymerDart.callMethod('propertyAccessorFactory', [
        name,
        (dartInstance) {
          var mirror = (declaration as dynamic).isStatic
              ? jsProxyReflectable.reflectType(type)
              : jsProxyReflectable.reflect(dartInstance);
          return convertToJs(mirror.invokeGetter(name));
        }
      ]),
      'configurable': false,
    };
    if (!isFinal(declaration)) {
      descriptor['set'] = _polymerDart.callMethod('propertySetterFactory', [
        name,
        (dartInstance, value) {
          var mirror = (declaration as dynamic).isStatic
              ? jsProxyReflectable.reflectType(type)
              : jsProxyReflectable.reflect(dartInstance);
          mirror.invokeSetter(name, convertToDart(value));
        }
      ]);
    }
    // Add a proxy getter/setter for this property.
    context['Object'].callMethod(
        'defineProperty', [prototype, name, new JsObject.jsify(descriptor),]);
  } else if (declaration is MethodMirror) {
    // TODO(jakemac): consolidate this code with the code in properties.dart.
    prototype[name] = _polymerDart.callMethod('invokeDartFactory', [
      (dartInstance, arguments) {
        var newArgs = arguments.map((arg) => convertToDart(arg)).toList();
        var mirror = declaration.isStatic
            ? jsProxyReflectable.reflectType(type)
            : jsProxyReflectable.reflect(dartInstance);
        return convertToJs(mirror.invoke(name, newArgs));
      }
    ]);
  } else {
    throw 'Unrecognized declaration `$name` for type `$type`: $declaration';
  }
}
