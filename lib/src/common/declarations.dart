// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.declarations;

import 'package:reflectable/reflectable.dart';
import '../../polymer_micro.dart';

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
    {bool where(String name, DeclarationMirror declaration)}) {
  var typeMirror = reflectionClass.reflectType(type);
  var declarations = {};
  var superClass = typeMirror;
  while (superClass != null && !_isPolymerMixin(superClass.mixin)) {
    superClass.declarations.forEach((name, declaration) {
      if (declarations.containsKey(name)) return;
      if (where != null && !where(name, declaration)) return;
      declarations[name] = declaration;
    });
    superClass = _getSuper(superClass);
  }
  return declarations;
}

bool _isPolymerMixin(ClassMirror clazz) {
  return clazz.reflectedType == PolymerMixin ||
      clazz.reflectedType == PolymerBase;
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
