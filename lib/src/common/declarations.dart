library polymer.src.common.declarations;

import 'package:reflectable/reflectable.dart';

typedef bool _WhereFn(String name, DeclarationMirror declaration);

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
