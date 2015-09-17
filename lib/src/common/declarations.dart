library polymer.src.common.declarations;

import 'package:reflectable/reflectable.dart';

typedef bool _WhereFn(String name, DeclarationMirror declaration);

/// Retrieves all the declarations for a class, given a [Reflectable] instance.
/// If a [_WhereFn] is supplied then it only returns the declarations which
/// return true from that.
Map<String, DeclarationMirror> declarationsFor(
    Type type, Reflectable reflectionClass, {_WhereFn where}) {
  var typeMirror;
  try {
    typeMirror = reflectionClass.reflectType(type);
  } catch (e) {
    throw 'type $type is missing the $reflectionClass annotation';
  }
  var declarations = {};
  var superClass = typeMirror;
  while (superClass != null && superClass.reflectedType != Object) {
    superClass.declarations.forEach((name, declaration) {
      if (declarations.containsKey(name)) return;
      if (where != null && !where(name, declaration)) return;
      declarations[name] = declaration;
    });
    superClass = _getSuper(superClass);
  }
  return declarations;
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
