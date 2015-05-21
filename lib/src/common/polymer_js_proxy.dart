// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.src.common.polymer_js_proxy;

import 'dart:html';
import 'dart:js';

import '../micro/attributes.dart';
import '../micro/properties.dart';

final JsObject _polymerBase = context['Polymer']['Base'];
final JsFunction _constructor = (context['Polymer'] as JsFunction).apply(
    [new JsObject.jsify({'is': 'dart-polymer-proxy'})]);

// Basic api for polymer proxies
abstract class PolymerProxy {
  JsObject get jsThis;
}

/**
 * Current approach, create a dummy js element and bash over all its dom methods
 * to actually modify the current element. Binds this to the actual js object
 * which is easier to reason about.
 *
 * Upsides:
 *   - This is what you think it is inside of the js functions.
 *   - Tied to dom apis not polymer apis (theoretically more stable).
 *   - Don't cross the language boundary for every function call, just the dom
 *     calls.
 * Downsides:
 *   - Extra js element created for every dart element.
 *   - If we miss a dom api, then its going to modify the dummy object.
 */
abstract class PolymerJsDomProxy implements PolymerProxy, Element, Properties {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) {
      _jsThis = new JsObject(_constructor);
      _jsThis['getAttribute'] = (String name) => attributes[name];
      _jsThis['hasAttribute'] = (String name) => attributes.containsKey(name);
      _jsThis['setAttribute'] =
          (String name, String value) => attributes[name] = value;
      _jsThis['removeAttribute'] = (String name) => attributes.remove(name);

      // Getter for attributes property!
      context['Object'].callMethod('defineProperty', [
        _jsThis,
        'attributes',
        new JsObject.jsify({
          'get': () {
            var attributeList = [];
            attributes.forEach((k, v) {
              attributeList.add({'name': k, 'value': v});
            });
            return new JsObject.jsify(attributeList);
          }
        }),
      ]);

      // Properties proxies
      _jsThis['getPropertyInfo'] = (property) =>
          getPropertyInfo(property).toJsObject();
    }
    return _jsThis;
  }
}

/**
 * Alternative approach, proxy the methods on the js prototype back to it. Binds
 * this to the dart custom element.
 *
 * Upsides:
 *   - Don't have to create a duplicate js element for each dart element, just a
 *     proxy object.
 *   - All dom operations just work, don't have to track new browser apis.
 * Downsides:
 *   - Have to proxy the whole polymer prototype back to itself.
 *   - Cross the language barrier twice for every function call from js code.
 */
abstract class PolymerJsProtoProxy implements PolymerProxy, Element, Properties {
  JsObject _jsThis;
  JsObject get jsThis {
    if (_jsThis == null) {
      _jsThis = new JsObject.fromBrowserObject(this);
      // General proxies
      // HACK!!!!
      _jsThis['behaviors'] = new JsObject.jsify([]);

      // Attributes proxies
      _jsThis['_marshalAttributes'] = () =>
          (_polymerBase['_marshalAttributes'] as JsFunction).apply(
              [], thisArg: jsThis);
      _jsThis['_installHostAttributes'] = (attributes) =>
          (_polymerBase['_installHostAttributes'] as JsFunction).apply(
              [attributes], thisArg: jsThis);
      _jsThis['_applyAttributes'] = (node, attributes) =>
          (_polymerBase['_applyAttributes'] as JsFunction).apply(
             [node, attributes], thisArg: jsThis);
      _jsThis['_takeAttributes'] = () =>
          (_polymerBase['_takeAttributes'] as JsFunction).apply(
              [], thisArg: jsThis);
      _jsThis['_takeAttributesToModel'] = (model) =>
          (_polymerBase['_takeAttributesToModel'] as JsFunction).apply(
              [model], thisArg: jsThis);
      _jsThis['setAttributeToProperty'] = (model, name) =>
          (_polymerBase['setAttributeToProperty'] as JsFunction).apply(
              [model, name], thisArg: jsThis);
      _jsThis['reflectPropertyToAttribute'] = (name) =>
          (_polymerBase['reflectPropertyToAttribute'] as JsFunction).apply(
              [name], thisArg: jsThis);
      _jsThis['serializeValueToAttribute'] = (value, attribute, node) =>
          (_polymerBase['serializeValueToAttribute'] as JsFunction).apply(
              [value, attribute, node], thisArg: jsThis);
      _jsThis['deserialize'] = (name, type) =>
          (_polymerBase['deserialize'] as JsFunction).apply(
              [name, type], thisArg: jsThis);
      _jsThis['serialize'] = (value) =>
          (_polymerBase['serialize'] as JsFunction).apply(
              [value], thisArg: jsThis);

      // Properties proxies
      _jsThis['getPropertyInfo'] = (property) =>
          getPropertyInfo(property).toJsObject();
//          (_polymerBase['getPropertyInfo'] as JsFunction).apply(
//              [property], thisArg: jsThis);
//
//      _jsThis['_getPropertyInfo'] = (property, properties) =>
//          (_polymerBase['_getPropertyInfo'] as JsFunction).apply(
//              [property, properties], thisArg: jsThis);
    }
    return _jsThis;
  }
}
