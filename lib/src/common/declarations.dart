library polymer.src.common.declarations;

import 'package:reflectable/reflectable.dart';
import '../../polymer_micro.dart';

typedef bool _DeclarationWhereFn(String name, DeclarationMirror declaration);
typedef bool _ClassWhereFn(ClassMirror mirror);

List<ClassMirror> mixinsFor(
    Type type, Reflectable reflectionClass, {_ClassWhereFn where}) {
  var typeMirror = _reflect(type, reflectionClass);
  var mixins = [];
  var superClass = _getSuper(typeMirror);
  while(superClass != null && superClass.mixin.reflectedType != PolymerMixin) {
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
    Type type, Reflectable reflectionClass, {_DeclarationWhereFn where}) {
  var typeMirror = _reflect(type, reflectionClass);
  var declarations = {};
  var superClass = typeMirror;
  while (superClass != null && superClass.mixin.reflectedType != PolymerMixin) {
    superClass.declarations.forEach((name, declaration) {
      if (declarations.containsKey(name)) return;
      if (where != null && !where(name, declaration)) return;
      declarations[name] = declaration;
    });
    superClass = _getSuper(superClass);
  }
  return declarations;
}

ClassMirror _reflect(Type type, Reflectable reflectionClass) {
  try {
    return reflectionClass.reflectType(type);
  } catch (e) {
    throw 'type $type is missing the $reflectionClass annotation';
  }
}

ClassMirror _getSuper(ClassMirror clazz) {
  // Currently throws post-transform if superclass isn't annotated with a
  // [Reflectable] class.
  try {
    return clazz.superclass;
  } catch(e) {
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
  return declaration is MethodMirror && declaration.isRegularMethod;
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
