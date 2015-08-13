library polymer.src.common.behavior;

import 'dart:js';
import 'package:reflectable/reflectable.dart';
import 'js_proxy.dart';
import 'polymer_descriptor.dart';

typedef void _VoidFn();

// Interface for behavior annotations.
abstract class BehaviorInterface {
  // Returns the JsObject created for this behavior.
  JsObject getBehavior(Type type);
}

Map<Type, JsObject> _behaviorsByType = {};

const String _lifecycleMethodsPattern =
    r'^created|attached|detached|attributeChanged$';
final RegExp _lifecycleMethodsRegex = new RegExp(_lifecycleMethodsPattern);

// Annotation class for behaviors written in dart.
class Behavior extends Reflectable implements BehaviorInterface {
  JsObject getBehavior(Type type) {
    return _behaviorsByType.putIfAbsent(type, () {
      var obj = new JsObject(context['Object']);

      // Add an entry for each static lifecycle method. These methods must take
      // a `this` arg as the first argument.
      var typeMirror = this.reflectType(type);
      typeMirror.staticMembers.forEach((String name, MethodMirror method) {
        if (!_lifecycleMethodsRegex.hasMatch(name)) return;
        if (name == 'attributeChanged') {
          obj[name] = new JsFunction.withThis(
                  (thisArg, String attributeName, Type type, value) {
            typeMirror.invoke(
                name, [dartValue(thisArg), attributeName, type, value]);
          });
        } else {
          obj[name] = new JsFunction.withThis((thisArg) {
            typeMirror.invoke(name, [thisArg]);
          });
        }
      });

      return obj;
    });
  }

  const Behavior()
      : super(declarationsCapability, typeCapability, const StaticInvokeCapability(_lifecycleMethodsPattern));
}
const behavior = const Behavior();

// Annotation class for wrappers around behaviors written in javascript.
class BehaviorProxy implements BehaviorInterface {
  // Path within js global context object to the original js behavior object.
  final List<String> _jsPath;

  // Returns the actual behavior.
  JsObject getBehavior(Type type) {
    return _behaviorsByType.putIfAbsent(type, () {
      if (_jsPath.isEmpty) {
        throw 'Invalid empty path for BehaviorProxy $_jsPath.';
      }
      var obj = context;
      for (var part in _jsPath) {
        obj = obj[part];
      }
      return obj;
    });
  }

  const BehaviorProxy(this._jsPath);
}
