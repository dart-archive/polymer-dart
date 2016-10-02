// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// Use this annotation to publish a property as an attribute.
///
/// You can also use [PublishedProperty] to provide additional information,
/// such as automatically syncing the property back to the attribute.
///
/// For example:
///
///     class MyPlaybackElement extends PolymerElement {
///       // This will be available as an HTML attribute, for example:
///       //
///       //     <my-playback volume="11">
///       //
///       // It will support initialization and data-binding via <template>:
///       //
///       //     <template>
///       //       <my-playback volume="{{x}}">
///       //     </template>
///       //
///       // If the template is instantiated or given a model, `x` will be
///       // used for this field and updated whenever `volume` changes.
///       @published
///       double get volume => readValue(#volume);
///       set volume(double newValue) => writeValue(#volume, newValue);
///
///       // This will be available as an HTML attribute, like above, but it
///       // will also serialize values set to the property to the attribute.
///       // In other words, attributes['volume2'] will contain a serialized
///       // version of this field.
///       @PublishedProperty(reflect: true)
///       double get volume2 => readValue(#volume2);
///       set volume2(double newValue) => writeValue(#volume2, newValue);
///     }
///
/// **Important note**: the pattern using `readValue` and `writeValue`
/// guarantees that reading the property will give you the latest value at any
/// given time, even if change notifications have not been propagated.
///
/// We still support using @published on a field, but this will not
/// provide the same guarantees, so this is discouraged. For example:
///
///       // Avoid this if possible. This will be available as an HTML
///       // attribute too, but you might need to delay reading volume3
///       // asynchronously to guarantee that you read the latest value
///       // set through bindings.
///       @published double volume3;
const published = const PublishedProperty();

/// An annotation used to publish a field as an attribute. See [published].
class PublishedProperty extends ObservableProperty {
  /// Whether the property value should be reflected back to the HTML attribute.
  final bool reflect;

  const PublishedProperty({this.reflect: false});
}

/// Use this type to observe a property and have the method be called when it
/// changes. For example:
///
///     @ObserveProperty('foo.bar baz qux')
///     validate() {
///       // use this.foo.bar, this.baz, and this.qux in validation
///       ...
///     }
///
/// Note that you can observe a property path, and more than a single property
/// can be specified in a space-delimited list or as a constant List.
class ObserveProperty {
  final _names;

  List<String> get names {
    var n = _names;
    // TODO(jmesserly): the bogus '$n' is to workaround a dart2js bug, otherwise
    // it generates an incorrect call site.
    if (n is String) return '$n'.split(' ');
    if (n is! Iterable) {
      throw new UnsupportedError('ObserveProperty takes either an Iterable of '
          'names, or a space separated String, instead of `$n`.');
    }
    return n;
  }

  const ObserveProperty(this._names);
}

/// Use this to create computed properties that are updated automatically. The
/// annotation includes a polymer expression that describes how this property
/// value can be expressed in terms of the values of other properties. For
/// example:
///
///     class MyPlaybackElement extends PolymerElement {
///       @observable int x;
///
///       // Reading xTimes2 will return x * 2.
///       @ComputedProperty('x * 2')
///       int get xTimes2 => readValue(#xTimes2);
///
/// If the polymer expression is assignable, you can also define a setter for
/// it. For example:
///
///       // Reading c will return a.b, writing c will update a.b.
///       @ComputedProperty('a.b')
///       get c => readValue(#c);
///       set c(newValue) => writeValue(#c, newValue);
///
/// The expression can do anything that is allowed in a polymer expresssion,
/// even making calls to methods in your element. However, dependencies that are
/// only used within those methods and that are not visible in the polymer
/// expression, will not be observed. For example:
///
///       // Because `x` only appears inside method `m`, we will not notice
///       // that `d` has changed if `x` is modified. However, `d` will be
///       // updated whenever `c` changes.
///       @ComputedProperty('m(c)')
///       get d => readValue(#d);
///
///       m(c) => c + x;
class ComputedProperty {
  /// A polymer expression, evaluated in the context of the custom element where
  /// this annotation is used.
  final String expression;

  const ComputedProperty(this.expression);
}

/// Base class for PolymerElements deriving from HtmlElement.
///
/// See [Polymer].
class PolymerElement extends HtmlElement with Polymer, AutoObservable {
  PolymerElement.created() : super.created() {
    polymerCreated();
  }
}

/// The mixin class for Polymer elements. It provides convenience features on
/// top of the custom elements web standard.
///
/// If this class is used as a mixin,
/// you must call `polymerCreated()` from the body of your constructor.
abstract class Polymer implements Element, Observable, NodeBindExtension {

  // TODO(jmesserly): should this really be public?
  /// Regular expression that matches data-bindings.
  static final bindPattern = new RegExp(r'\{\{([^{}]*)}}');

  /// Like [document.register] but for Polymer elements.
  ///
  /// Use the [name] to specify custom elment's tag name, for example:
  /// "fancy-button" if the tag is used as `<fancy-button>`.
  ///
  /// The [type] is the type to construct. If not supplied, it defaults to
  /// [PolymerElement].
  // NOTE: this is called "element" in src/declaration/polymer-element.js, and
  // exported as "Polymer".
  static void register(String name, [Type type]) {
    //console.log('registering [' + name + ']');
    if (type == null) type = PolymerElement;

    _typesByName[name] = type;

    // Dart note: here we notify JS of the element registration. We don't pass
    // the Dart type because we will handle that in PolymerDeclaration.
    // See _hookJsPolymerDeclaration for how this is done.
    PolymerJs.constructor.apply([name]);
    (js.context['HTMLElement']['register'] as JsFunction)
        .apply([name, js.context['HTMLElement']['prototype']]);
  }

  /// Register a custom element that has no associated `<polymer-element>`.
  /// Unlike [register] this will always perform synchronous registration and
  /// by the time this method returns the element will be available using
  /// [document.createElement] or by modifying the HTML to include the element.
  static void registerSync(String name, Type type,
      {String extendsTag, Document doc, Node template}) {

    // Our normal registration, this will queue up the name->type association.
    register(name, type);

    // Build a polymer-element and initialize it to register
    if (doc == null) doc = document;
    var poly = doc.createElement('polymer-element');
    poly.attributes['name'] = name;
    if (extendsTag != null) poly.attributes['extends'] = extendsTag;
    if (template != null) poly.append(template);

    // TODO(jmesserly): conceptually this is just:
    //     new JsObject.fromBrowserObject(poly).callMethod('init')
    //
    // However doing it that way hits an issue with JS-interop in IE10: we get a
    // JsObject that wraps something other than `poly`, due to improper caching.
    // By reusing _polymerElementProto that we used for 'register', we can
    // then call apply on it to invoke init() with the correct `this` pointer.
    JsFunction init = _polymerElementProto['init'];
    init.apply([], thisArg: poly);
  }

  // Warning for when people try to use `importElements` or `import`.
  static const String _DYNAMIC_IMPORT_WARNING = 'Dynamically loading html '
      'imports has very limited support right now in dart, see '
      'http://dartbug.com/17873.';

  /// Loads the set of HTMLImports contained in `node`. Returns a future that
  /// resolves when all the imports have been loaded. This method can be used to
  /// lazily load imports. For example, given a template:
  ///
  ///     <template>
  ///       <link rel="import" href="my-import1.html">
  ///       <link rel="import" href="my-import2.html">
  ///     </template>
  ///
  ///     Polymer.importElements(template.content)
  ///         .then((_) => print('imports lazily loaded'));
  ///
  /// Dart Note: This has very limited support in dart, http://dartbug.com/17873
  // Dart Note: From src/lib/import.js For now proxy to the JS methods,
  // because we want to share the loader with polymer.js for interop purposes.
  static Future importElements(Node elementOrFragment) {
    print(_DYNAMIC_IMPORT_WARNING);
    return PolymerJs.importElements(elementOrFragment);
  }

  /// Loads an HTMLImport for each url specified in the `urls` array. Notifies
  /// when all the imports have loaded by calling the `callback` function
  /// argument. This method can be used to lazily load imports. For example,
  /// For example,
  ///
  ///     Polymer.import(['my-import1.html', 'my-import2.html'])
  ///         .then((_) => print('imports lazily loaded'));
  ///
  /// Dart Note: This has very limited support in dart, http://dartbug.com/17873
  // Dart Note: From src/lib/import.js. For now proxy to the JS methods,
  // because we want to share the loader with polymer.js for interop purposes.
  static Future import(List urls) {
    print(_DYNAMIC_IMPORT_WARNING);
    return PolymerJs.import(urls);
  }

  /// Deprecated: Use `import` instead.
  @deprecated
  static Future importUrls(List urls) {
    return import(urls);
  }

  /// Completes when polymer js is ready.
  static final Completer _onReady = new Completer();

  /// Completes when all initialization is done.
  static final Completer _onInitDone = new Completer();

  /// Future indicating that the Polymer library has been loaded and is ready
  /// for use.
  static Future get onReady =>
      Future.wait([_onReady.future, _onInitDone.future]);

  /// Returns a list of elements that have had polymer-elements created but
  /// are not yet ready to register. The list is an array of element
  /// definitions.
  static List<Element> get waitingFor => PolymerJs.waitingFor;

  /// Forces polymer to register any pending elements. Can be used to abort
  /// waiting for elements that are partially defined.
  static forceReady([int timeout]) => PolymerJs.forceReady(timeout);

  /// The most derived `<polymer-element>` declaration for this element.
  PolymerDeclaration get element => _element;
  PolymerDeclaration _element;

  /// Deprecated: use [element] instead.
  @deprecated PolymerDeclaration get declaration => _element;

  Map<String, StreamSubscription> _namedObservers;
  List<Bindable> _observers = [];

  bool _unbound; // lazy-initialized
  PolymerJob _unbindAllJob;

  CompoundObserver _propertyObserver;
  bool _readied = false;

  JsObject _jsElem;

  /// Returns the object that should be used as the event controller for
  /// event bindings in this element's template. If set, this will override the
  /// normal controller lookup.
  // TODO(jmesserly): we need to use a JS-writable property as our backing
  // store, because of elements such as:
  // https://github.com/Polymer/core-overlay/blob/eeb14853/core-overlay-layer.html#L78
  get eventController => _jsElem['eventController'];
  set eventController(value) {
    _jsElem['eventController'] = value;
  }

  bool get hasBeenAttached => _hasBeenAttached;
  bool _hasBeenAttached = false;

  /// Gets the shadow root associated with the corresponding custom element.
  ///
  /// This is identical to [shadowRoot], unless there are multiple levels of
  /// inheritance and they each have their own shadow root. For example,
  /// this can happen if the base class and subclass both have `<template>` tags
  /// in their `<polymer-element>` tags.
  // TODO(jmesserly): should expose this as an immutable map.
  // Similar issue as $.
  final Map<String, ShadowRoot> shadowRoots =
      new LinkedHashMap<String, ShadowRoot>();

  /// Map of items in the shadow root(s) by their [Element.id].
  // TODO(jmesserly): various issues:
  // * wrap in UnmodifiableMapView?
  // * should we have an object that implements noSuchMethod?
  // * should the map have a key order (e.g. LinkedHash or SplayTree)?
  // * should this be a live list? Polymer doesn't, maybe due to JS limitations?
  // Note: this is observable to support $['someId'] being used in templates.
  // The template is stamped before $ is populated, so we need observation if
  // we want it to be usable in bindings.
  final Map<String, dynamic> $ = new ObservableMap<String, dynamic>();

  /// Use to override the default syntax for polymer-elements.
  /// By default this will be null, which causes [instanceTemplate] to use
  /// the template's bindingDelegate or the [element.syntax], in that order.
  PolymerExpressions get syntax => null;

  bool get _elementPrepared => _element != null;

  /// Retrieves the custom element name. It should be used instead
  /// of localName, see: https://github.com/Polymer/polymer-dev/issues/26
  String get _name {
    if (_element != null) return _element.name;
    var isAttr = attributes['is'];
    return (isAttr == null || isAttr == '') ? localName : isAttr;
  }

  /// By default the data bindings will be cleaned up when this custom element
  /// is detached from the document. Overriding this to return `true` will
  /// prevent that from happening.
  bool get preventDispose => false;

  /// Properties exposed by this element.
  // Dart note: unlike Javascript we can't override the original property on
  // the object, so we use this mechanism instead to define properties. See more
  // details in [_PropertyAccessor].
  Map<Symbol, _PropertyAccessor> _properties = {};

  /// Helper to implement a property with the given [name]. This is used for
  /// normal and computed properties. Normal properties can provide the initial
  /// value using the [initialValue] function. Computed properties ignore
  /// [initialValue], their value is derived from the expression in the
  /// [ComputedProperty] annotation that appears above the getter that uses this
  /// helper.
  readValue(Symbol name, [initialValue()]) {
    var property = _properties[name];
    if (property == null) {
      var value;
      // Dart note: most computed properties are created in advance in
      // createComputedProperties, but if one computed property depends on
      // another, the declaration order might matter. Rather than trying to
      // register them in order, we include here also the option of lazily
      // creating the property accessor on the first read.
      var binding = _getBindingForComputedProperty(name);
      if (binding == null) {
        // normal property
        value = initialValue != null ? initialValue() : null;
      } else {
        value = binding.value;
      }
      property = _properties[name] = new _PropertyAccessor(name, this, value);
    }
    return property.value;
  }

  /// Helper to implement a setter of a property with the given [name] on a
  /// polymer element. This can be used on normal properties and also on
  /// computed properties, as long as the expression used for the computed
  /// property is assignable (see [ComputedProperty]).
  writeValue(Symbol name, newValue) {
    var property = _properties[name];
    if (property == null) {
      // Note: computed properties are created in advance in
      // createComputedProperties, so we should only need to create here
      // non-computed properties.
      property = _properties[name] = new _PropertyAccessor(name, this, null);
    }
    property.value = newValue;
  }

  /// If this class is used as a mixin, this method must be called from inside
  /// of the `created()` constructor.
  ///
  /// If this class is a superclass, calling `super.created()` is sufficient.
  void polymerCreated() {
    var t = nodeBind(this).templateInstance;
    if (t != null && t.model != null) {
      window.console.warn('Attributes on $_name were data bound '
          'prior to Polymer upgrading the element. This may result in '
          'incorrect binding types.');
    }
    prepareElement();
    if (!isTemplateStagingDocument(ownerDocument)) {
      _makeElementReady();
    }
  }

  /// *Deprecated* use [shadowRoots] instead.
  @deprecated
  ShadowRoot getShadowRoot(String customTagName) => shadowRoots[customTagName];

  void prepareElement() {
    if (_elementPrepared) {
      window.console.warn('Element already prepared: $_name');
      return;
    }
    _initJsObject();
    // Dart note: get the corresponding <polymer-element> declaration.
    _element = _getDeclaration(_name);
    // install property storage
    createPropertyObserver();
    openPropertyObserver();
    // install boilerplate attributes
    copyInstanceAttributes();
    // process input attributes
    takeAttributes();
    // add event listeners
    addHostListeners();
  }

  /// Initialize JS interop for this element. For now we just initialize the
  /// JsObject, but in the future we could also initialize JS APIs here.
  _initJsObject() {
    _jsElem = new JsObject.fromBrowserObject(this);
  }

  /// Deprecated: This is no longer a public method.
  @deprecated
  makeElementReady() => _makeElementReady();

  _makeElementReady() {
    if (_readied) return;
    _readied = true;
    createComputedProperties();

    parseDeclarations(_element);
    // NOTE: Support use of the `unresolved` attribute to help polyfill
    // custom elements' `:unresolved` feature.
    attributes.remove('unresolved');
    // user entry point
    _readyLog.info(() => '[$this]: ready');
    ready();
  }

  /// Lifecycle method called when the element has populated it's `shadowRoot`,
  /// prepared data-observation, and made itself ready for API interaction.
  /// To wait until the element has been attached to the default view, use
  /// [attached] or [domReady].
  void ready() {}

  /// Implement to access custom elements in dom descendants, ancestors,
  /// or siblings. Because custom elements upgrade in document order,
  /// elements accessed in `ready` or `attached` may not be upgraded. When
  /// `domReady` is called, all registered custom elements are guaranteed
  /// to have been upgraded.
  void domReady() {}

  void attached() {
    if (!_elementPrepared) {
      // Dart specific message for a common issue.
      throw new StateError('polymerCreated was not called for custom element '
          '$_name, this should normally be done in the .created() if Polymer '
          'is used as a mixin.');
    }

    cancelUnbindAll();
    if (!hasBeenAttached) {
      _hasBeenAttached = true;
      async((_) => domReady());
    }
  }

  void detached() {
    if (!preventDispose) asyncUnbindAll();
  }

  /// Walks the prototype-chain of this element and allows specific
  /// classes a chance to process static declarations.
  ///
  /// In particular, each polymer-element has it's own `template`.
  /// `parseDeclarations` is used to accumulate all element `template`s
  /// from an inheritance chain.
  ///
  /// `parseDeclaration` static methods implemented in the chain are called
  /// recursively, oldest first, with the `<polymer-element>` associated
  /// with the current prototype passed as an argument.
  ///
  /// An element may override this method to customize shadow-root generation.
  void parseDeclarations(PolymerDeclaration declaration) {
    if (declaration != null) {
      parseDeclarations(declaration.superDeclaration);
      parseDeclaration(declaration.element);
    }
  }

  /// Perform init-time actions based on static information in the
  /// `<polymer-element>` instance argument.
  ///
  /// For example, the standard implementation locates the template associated
  /// with the given `<polymer-element>` and stamps it into a shadow-root to
  /// implement shadow inheritance.
  ///
  /// An element may override this method for custom behavior.
  void parseDeclaration(Element elementElement) {
    var template = fetchTemplate(elementElement);

    if (template != null) {
      var root = shadowFromTemplate(template);

      var name = elementElement.attributes['name'];
      if (name == null) return;
      shadowRoots[name] = root;
    }
  }

  /// Given a `<polymer-element>`, find an associated template (if any) to be
  /// used for shadow-root generation.
  ///
  /// An element may override this method for custom behavior.
  Element fetchTemplate(Element elementElement) =>
      elementElement.querySelector('template');

  /// Utility function that stamps a `<template>` into light-dom.
  Node lightFromTemplate(Element template, [Node refNode]) {
    if (template == null) return null;

    // TODO(sorvell): mark this element as an event controller so that
    // event listeners on bound nodes inside it will be called on it.
    // Note, the expectation here is that events on all descendants
    // should be handled by this element.
    eventController = this;

    // stamp template
    // which includes parsing and applying MDV bindings before being
    // inserted (to avoid {{}} in attribute values)
    // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
    var dom = instanceTemplate(template);
    // append to shadow dom
    if (refNode != null) {
      append(dom);
    } else {
      insertBefore(dom, refNode);
    }
    // perform post-construction initialization tasks on ahem, light root
    shadowRootReady(this);
    // return the created shadow root
    return dom;
  }

  /// Utility function that creates a shadow root from a `<template>`.
  ///
  /// The base implementation will return a [ShadowRoot], but you can replace it
  /// with your own code and skip ShadowRoot creation. In that case, you should
  /// return `null`.
  ///
  /// In your overridden method, you can use [instanceTemplate] to stamp the
  /// template and initialize data binding, and [shadowRootReady] to intialize
  /// other Polymer features like event handlers. It is fine to call
  /// shadowRootReady with a node other than a ShadowRoot such as with `this`.
  ShadowRoot shadowFromTemplate(Element template) {
    if (template == null) return null;
    // make a shadow root
    var root = createShadowRoot();
    // stamp template
    // which includes parsing and applying MDV bindings before being
    // inserted (to avoid {{}} in attribute values)
    // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
    var dom = instanceTemplate(template);
    // append to shadow dom
    root.append(dom);
    // perform post-construction initialization tasks on shadow root
    shadowRootReady(root);
    // return the created shadow root
    return root;
  }

  void shadowRootReady(Node root) {
    // locate nodes with id and store references to them in this.$ hash
    marshalNodeReferences(root);
  }

  /// Locate nodes with id and store references to them in [$] hash.
  void marshalNodeReferences(Node root) {
    if (root == null) return;
    for (var n in (root as dynamic).querySelectorAll('[id]')) {
      $[n.id] = n;
    }
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    if (name != 'class' && name != 'style') {
      attributeToProperty(name, newValue);
    }
  }

  // TODO(jmesserly): this could be a top level method.
  /// Returns a future when `node` changes, or when its children or subtree
  /// changes.
  ///
  /// Use [MutationObserver] if you want to listen to a stream of changes.
  Future<List<MutationRecord>> onMutation(Node node) {
    var completer = new Completer();
    new MutationObserver((mutations, observer) {
      observer.disconnect();
      completer.complete(mutations);
    })..observe(node, childList: true, subtree: true);
    return completer.future;
  }

  // copy attributes defined in the element declaration to the instance
  // e.g. <polymer-element name="x-foo" tabIndex="0"> tabIndex is copied
  // to the element instance here.
  void copyInstanceAttributes() {
    _element._instanceAttributes.forEach((name, value) {
      attributes.putIfAbsent(name, () => value);
    });
  }

  void takeAttributes() {
    if (_element._publishLC == null) return;
    attributes.forEach(attributeToProperty);
  }

  /// If attribute [name] is mapped to a property, deserialize
  /// [value] into that property.
  void attributeToProperty(String name, String value) {
    // try to match this attribute to a property (attributes are
    // all lower-case, so this is case-insensitive search)
    var decl = propertyForAttribute(name);
    if (decl == null) return;

    // filter out 'mustached' values, these are to be
    // replaced with bound-data and are not yet values
    // themselves.
    if (value == null || value.contains(Polymer.bindPattern)) return;

    final currentValue = smoke.read(this, decl.name);

    // deserialize Boolean or Number values from attribute
    var type = decl.type;
    if ((type == Object || type == dynamic) && currentValue != null) {
      // Attempt to infer field type from the current value.
      type = currentValue.runtimeType;
    }
    final newValue = deserializeValue(value, currentValue, type);

    // only act if the value has changed
    if (!identical(newValue, currentValue)) {
      // install new value (has side-effects)
      smoke.write(this, decl.name, newValue);
    }
  }

  /// Return the published property matching name, or null.
  // TODO(jmesserly): should we just return Symbol here?
  smoke.Declaration propertyForAttribute(String name) {
    final publishLC = _element._publishLC;
    if (publishLC == null) return null;
    return publishLC[name];
  }

  /// Convert representation of [value] based on [type] and [currentValue].
  Object deserializeValue(String value, Object currentValue, Type type) =>
      deserialize.deserializeValue(value, currentValue, type);

  String serializeValue(Object value) {
    if (value == null) return null;

    if (value is bool) {
      return _toBoolean(value) ? '' : null;
    } else if (value is String || value is num) {
      return '$value';
    }
    return null;
  }

  void reflectPropertyToAttribute(String path) {
    // TODO(sjmiles): consider memoizing this
    // try to intelligently serialize property value
    final propValue = new PropertyPath(path).getValueFrom(this);
    final serializedValue = serializeValue(propValue);
    // boolean properties must reflect as boolean attributes
    if (serializedValue != null) {
      attributes[path] = serializedValue;
      // TODO(sorvell): we should remove attr for all properties
      // that have undefined serialization; however, we will need to
      // refine the attr reflection system to achieve this; pica, for example,
      // relies on having inferredType object properties not removed as
      // attrs.
    } else if (propValue is bool) {
      attributes.remove(path);
    }
  }

  /// Creates the document fragment to use for each instance of the custom
  /// element, given the `<template>` node. By default this is equivalent to:
  ///
  ///     templateBind(template).createInstance(this, polymerSyntax);
  ///
  /// Where polymerSyntax is a singleton [PolymerExpressions] instance.
  ///
  /// You can override this method to change the instantiation behavior of the
  /// template, for example to use a different data-binding syntax.
  DocumentFragment instanceTemplate(Element template) {
    // ensure template is decorated (lets things like <tr template ...> work)
    TemplateBindExtension.decorate(template);
    var syntax = this.syntax;
    var t = templateBind(template);
    if (syntax == null && t.bindingDelegate == null) {
      syntax = element.syntax;
    }
    var dom = t.createInstance(this, syntax);
    _observers.addAll(getTemplateInstanceBindings(dom));
    return dom;
  }

  /// Called by TemplateBinding/NodeBind to setup a binding to the given
  /// property. It's overridden here to support property bindings in addition to
  /// attribute bindings that are supported by default.
  Bindable bind(String name, bindable, {bool oneTime: false}) {
    var decl = propertyForAttribute(name);
    if (decl == null) {
      // Cannot call super.bind because template_binding is its own package
      return nodeBindFallback(this).bind(name, bindable, oneTime: oneTime);
    } else {
      // use n-way Polymer binding
      var observer = bindProperty(decl.name, bindable, oneTime: oneTime);
      // NOTE: reflecting binding information is typically required only for
      // tooling. It has a performance cost so it's opt-in in Node.bind.
      if (enableBindingsReflection && observer != null) {
        // Dart note: this is not needed because of how _PolymerBinding works.
        //observer.path = bindable.path_;
        _recordBinding(name, observer);
      }
      var reflect = _element._reflect;

      // Get back to the (possibly camel-case) name for the property.
      var propName = smoke.symbolToName(decl.name);
      if (reflect != null && reflect.contains(propName)) {
        reflectPropertyToAttribute(propName);
      }
      return observer;
    }
  }

  _recordBinding(String name, observer) {
    if (bindings == null) bindings = {};
    this.bindings[name] = observer;
  }

  /// Called by TemplateBinding when all bindings on an element have been
  /// executed. This signals that all element inputs have been gathered and it's
  /// safe to ready the element, create shadow-root and start data-observation.
  bindFinished() => _makeElementReady();

  Map<String, Bindable> get bindings => nodeBindFallback(this).bindings;
  set bindings(Map value) {
    nodeBindFallback(this).bindings = value;
  }

  TemplateInstance get templateInstance =>
      nodeBindFallback(this).templateInstance;

  /// Called at detached time to signal that an element's bindings should be
  /// cleaned up. This is done asynchronously so that users have the chance to
  /// call `cancelUnbindAll` to prevent unbinding.
  void asyncUnbindAll() {
    if (_unbound == true) return;
    _unbindLog.fine(() => '[$_name] asyncUnbindAll');
    _unbindAllJob = scheduleJob(_unbindAllJob, unbindAll);
  }

  /// This method should rarely be used and only if `cancelUnbindAll` has been
  /// called to prevent element unbinding. In this case, the element's bindings
  /// will not be automatically cleaned up and it cannot be garbage collected by
  /// by the system. If memory pressure is a concern or a large amount of
  /// elements need to be managed in this way, `unbindAll` can be called to
  /// deactivate the element's bindings and allow its memory to be reclaimed.
  void unbindAll() {
    if (_unbound == true) return;
    closeObservers();
    closeNamedObservers();
    _unbound = true;
  }

  //// Call in `detached` to prevent the element from unbinding when it is
  //// detached from the dom. The element is unbound as a cleanup step that
  //// allows its memory to be reclaimed. If `cancelUnbindAll` is used, consider
  /// calling `unbindAll` when the element is no longer needed. This will allow
  /// its memory to be reclaimed.
  void cancelUnbindAll() {
    if (_unbound == true) {
      _unbindLog
          .warning(() => '[$_name] already unbound, cannot cancel unbindAll');
      return;
    }
    _unbindLog.fine(() => '[$_name] cancelUnbindAll');
    if (_unbindAllJob != null) {
      _unbindAllJob.stop();
      _unbindAllJob = null;
    }
  }

  static void _forNodeTree(Node node, void callback(Node node)) {
    if (node == null) return;

    callback(node);
    for (var child = node.firstChild; child != null; child = child.nextNode) {
      _forNodeTree(child, callback);
    }
  }

  /// Creates a CompoundObserver to observe property changes.
  /// NOTE, this is only done if there are any properties in the `_observe`
  /// object.
  void createPropertyObserver() {
    final observe = _element._observe;
    if (observe != null) {
      var o = _propertyObserver = new CompoundObserver();
      // keep track of property observer so we can shut it down
      _observers.add(o);

      for (var path in observe.keys) {
        o.addPath(this, path);

        // TODO(jmesserly): on the Polymer side it doesn't look like they
        // will observe arrays unless it is a length == 1 path.
        observeArrayValue(path, path.getValueFrom(this), null);
      }
    }
  }

  /// Start observing property changes.
  void openPropertyObserver() {
    if (_propertyObserver != null) {
      _propertyObserver.open(notifyPropertyChanges);
    }

    // Dart note: we need an extra listener only to continue supporting
    // @published properties that follow the old syntax until we get rid of it.
    // This workaround has timing issues so we prefer the new, not so nice,
    // syntax.
    if (_element._publish != null) {
      changes.listen(_propertyChangeWorkaround);
    }
  }

  /// Handler for property changes; routes changes to observing methods.
  /// Note: array valued properties are observed for array splices.
  void notifyPropertyChanges(List newValues, Map oldValues, List paths) {
    final observe = _element._observe;
    final called = new HashSet();

    oldValues.forEach((i, oldValue) {
      final newValue = newValues[i];

      // Date note: we don't need any special checking for null and undefined.

      // note: paths is of form [object, path, object, path]
      final path = paths[2 * i + 1];
      if (observe == null) return;

      var methods = observe[path];
      if (methods == null) return;

      for (var method in methods) {
        if (!called.add(method)) continue; // don't invoke more than once.

        observeArrayValue(path, newValue, oldValue);
        // Dart note: JS passes "arguments", so we pass along our args.
        // TODO(sorvell): call method with the set of values it's expecting;
        // e.g. 'foo bar': 'invalidate' expects the new and old values for
        // foo and bar. Currently we give only one of these and then
        // deliver all the arguments.
        smoke.invoke(
            this, method, [oldValue, newValue, newValues, oldValues, paths],
            adjust: true);
      }
    });
  }

  /// Force any pending property changes to synchronously deliver to handlers
  /// specified in the `observe` object.
  /// Note: normally changes are processed at microtask time.
  ///
  // Dart note: had to rename this to avoid colliding with
  // Observable.deliverChanges. Even worse, super calls aren't possible or
  // it prevents Polymer from being a mixin, so we can't override it even if
  // we wanted to.
  void deliverPropertyChanges() {
    if (_propertyObserver != null) {
      _propertyObserver.deliver();
    }
  }

  // Dart note: this workaround is only for old-style @published properties,
  // which have timing issues. See _bindOldStylePublishedProperty below.
  // TODO(sigmund): deprecate this.
  void _propertyChangeWorkaround(List<ChangeRecord> records) {
    for (var record in records) {
      if (record is! PropertyChangeRecord) continue;

      var name = record.name;
      // The setter of a new-style property will create an accessor in
      // _properties[name]. We can skip the workaround for those properties.
      if (_properties[name] != null) continue;
      _propertyChange(name, record.newValue, record.oldValue);
    }
  }

  void _propertyChange(Symbol nameSymbol, newValue, oldValue) {
    _watchLog.info(
        () => '[$this]: $nameSymbol changed from: $oldValue to: $newValue');
    var name = smoke.symbolToName(nameSymbol);
    var reflect = _element._reflect;
    if (reflect != null && reflect.contains(name)) {
      reflectPropertyToAttribute(name);
    }
  }

  void observeArrayValue(PropertyPath name, Object value, Object old) {
    final observe = _element._observe;
    if (observe == null) return;

    // we only care if there are registered side-effects
    var callbacks = observe[name];
    if (callbacks == null) return;

    // if we are observing the previous value, stop
    if (old is ObservableList) {
      _observeLog.fine(() => '[$_name] observeArrayValue: unregister $name');

      closeNamedObserver('${name}__array');
    }
    // if the new value is an array, begin observing it
    if (value is ObservableList) {
      _observeLog.fine(() => '[$_name] observeArrayValue: register $name');
      var sub = value.listChanges.listen((changes) {
        for (var callback in callbacks) {
          smoke.invoke(this, callback, [changes], adjust: true);
        }
      });
      registerNamedObserver('${name}__array', sub);
    }
  }

  emitPropertyChangeRecord(Symbol name, newValue, oldValue) {
    if (identical(oldValue, newValue)) return;
    _propertyChange(name, newValue, oldValue);
  }

  bindToAccessor(Symbol name, Bindable bindable, {resolveBindingValue: false}) {
    // Dart note: our pattern is to declare the initial value in the getter.  We
    // read it via smoke to ensure that the value is initialized correctly.
    var oldValue = smoke.read(this, name);
    var property = _properties[name];
    if (property == null) {
      // We know that _properties[name] is null only for old-style @published
      // properties. This fallback is here to make it easier to deprecate the
      // old-style of published properties, which have bad timing guarantees
      // (see comment in _PolymerBinding).
      return _bindOldStylePublishedProperty(name, bindable, oldValue);
    }

    property.bindable = bindable;
    var value = bindable.open(property.updateValue);

    if (resolveBindingValue) {
      // capture A's value if B's value is null or undefined,
      // otherwise use B's value
      var v = (value == null ? oldValue : value);
      if (!identical(value, oldValue)) {
        bindable.value = value = v;
      }
    }

    property.updateValue(value);
    var o = new _CloseOnlyBinding(property);
    _observers.add(o);
    return o;
  }

  // Dart note: this fallback uses our old-style binding mechanism to be able to
  // link @published properties with bindings. This mechanism is backwards from
  // what Javascript does because we can't override the original property. This
  // workaround also brings some timing issues which are described in detail in
  // dartbug.com/18343.
  // TODO(sigmund): deprecate old-style @published properties.
  _bindOldStylePublishedProperty(Symbol name, Bindable bindable, oldValue) {
    // capture A's value if B's value is null or undefined,
    // otherwise use B's value
    if (bindable.value == null) bindable.value = oldValue;

    var o = new _PolymerBinding(this, name, bindable);
    _observers.add(o);
    return o;
  }

  _getBindingForComputedProperty(Symbol name) {
    var exprString = element._computed[name];
    if (exprString == null) return null;
    var expr = PolymerExpressions.getExpression(exprString);
    return PolymerExpressions.getBinding(expr, this,
        globals: element.syntax.globals);
  }

  createComputedProperties() {
    var computed = this.element._computed;
    for (var name in computed.keys) {
      try {
        // Dart note: this is done in Javascript by modifying the prototype in
        // declaration/properties.js, we can't do that, so we do it here.
        var binding = _getBindingForComputedProperty(name);

        // Follow up note: ideally we would only create the accessor object
        // here, but some computed properties might depend on others and
        // evaluating `binding.value` could try to read the value of another
        // computed property that we haven't created yet. For this reason we
        // also allow to also create the accessor in [readValue].
        if (_properties[name] == null) {
          _properties[name] = new _PropertyAccessor(name, this, binding.value);
        }
        bindToAccessor(name, binding);
      } catch (e) {
        window.console.error('Failed to create computed property $name'
            ' (${computed[name]}): $e');
      }
    }
  }

  // Dart note: to simplify the code above we made registerObserver calls
  // directly invoke _observers.add/addAll.
  void closeObservers() {
    for (var o in _observers) {
      if (o != null) o.close();
    }
    _observers = [];
  }

  /// Bookkeeping observers for memory management.
  void registerNamedObserver(String name, StreamSubscription sub) {
    if (_namedObservers == null) {
      _namedObservers = new Map<String, StreamSubscription>();
    }
    _namedObservers[name] = sub;
  }

  bool closeNamedObserver(String name) {
    var sub = _namedObservers.remove(name);
    if (sub == null) return false;
    sub.cancel();
    return true;
  }

  void closeNamedObservers() {
    if (_namedObservers == null) return;
    for (var sub in _namedObservers.values) {
      if (sub != null) sub.cancel();
    }
    _namedObservers.clear();
    _namedObservers = null;
  }

  /// Bind the [name] property in this element to [bindable]. *Note* in Dart it
  /// is necessary to also define the field:
  ///
  ///     var myProperty;
  ///
  ///     ready() {
  ///       super.ready();
  ///       bindProperty(#myProperty,
  ///           new PathObserver(this, 'myModel.path.to.otherProp'));
  ///     }
  Bindable bindProperty(Symbol name, bindableOrValue, {oneTime: false}) {
    // Dart note: normally we only reach this code when we know it's a
    // property, but if someone uses bindProperty directly they might get a
    // NoSuchMethodError either from the getField below, or from the setField
    // inside PolymerBinding. That doesn't seem unreasonable, but it's a slight
    // difference from Polymer.js behavior.

    _bindLog.fine(() => 'bindProperty: [$bindableOrValue] to [$_name].[$name]');

    if (oneTime) {
      if (bindableOrValue is Bindable) {
        _bindLog.warning(() =>
            'bindProperty: expected non-bindable value n a one-time binding to '
            '[$_name].[$name], but found $bindableOrValue.');
      }
      smoke.write(this, name, bindableOrValue);
      return null;
    }

    return bindToAccessor(name, bindableOrValue, resolveBindingValue: true);
  }

  /// Attach event listeners on the host (this) element.
  void addHostListeners() {
    var events = _element._eventDelegates;
    if (events.isEmpty) return;

    _eventsLog.fine(() => '[$_name] addHostListeners: $events');

    // NOTE: host events look like bindings but really are not;
    // (1) we don't want the attribute to be set and (2) we want to support
    // multiple event listeners ('host' and 'instance') and Node.bind
    // by default supports 1 thing being bound.
    events.forEach((type, methodName) {
      // Dart note: the getEventHandler method is on our PolymerExpressions.
      PolymerGesturesJs.addEventListener(
          this, type,
          Zone.current.bindUnaryCallback(
              element.syntax.getEventHandler(this, this, methodName)));
    });
  }

  /// Calls [methodOrCallback] with [args] if it is a closure, otherwise, treat
  /// it as a method name in [object], and invoke it.
  void dispatchMethod(object, callbackOrMethod, List args) {
    _eventsLog.info(() => '>>> [$_name]: dispatch $callbackOrMethod');

    if (callbackOrMethod is Function) {
      int maxArgs = smoke.maxArgs(callbackOrMethod);
      if (maxArgs == -1) {
        _eventsLog.warning(
            'invalid callback: expected callback of 0, 1, 2, or 3 arguments');
      }
      args.length = maxArgs;
      Function.apply(callbackOrMethod, args);
    } else if (callbackOrMethod is String) {
      smoke.invoke(object, smoke.nameToSymbol(callbackOrMethod), args,
          adjust: true);
    } else {
      _eventsLog.warning('invalid callback');
    }

    _eventsLog.fine(() => '<<< [$_name]: dispatch $callbackOrMethod');
  }

  /// Call [methodName] method on this object with [args].
  invokeMethod(Symbol methodName, List args) =>
      smoke.invoke(this, methodName, args, adjust: true);

  /// Invokes a function asynchronously.
  /// This will call `Polymer.flush()` and then return a `new Timer`
  /// with the provided [method] and [timeout].
  ///
  /// If you would prefer to run the callback using
  /// [window.requestAnimationFrame], see the [async] method.
  ///
  /// To cancel, call [Timer.cancel] on the result of this method.
  Timer asyncTimer(void method(), Duration timeout) {
    // Dart note: "async" is split into 2 methods so it can have a sensible type
    // signatures. Also removed the various features that don't make sense in a
    // Dart world, like binding to "this" and taking arguments list.

    // when polyfilling Object.observe, ensure changes
    // propagate before executing the async method
    scheduleMicrotask(AutoObservable.dirtyCheck);
    PolymerJs.flush(); // for polymer-js interop
    return new Timer(timeout, method);
  }

  /// Invokes a function asynchronously. The context of the callback function is
  /// function is bound to 'this' automatically. Returns a handle which may be
  /// passed to cancelAsync to cancel the asynchronous call.
  ///
  /// If you would prefer to run the callback after a given duration, see
  /// the [asyncTimer] method.
  ///
  /// If you would like to cancel this, use [cancelAsync].
  int async(RequestAnimationFrameCallback method) {
    // when polyfilling Object.observe, ensure changes
    // propagate before executing the async method
    scheduleMicrotask(AutoObservable.dirtyCheck);
    PolymerJs.flush(); // for polymer-js interop
    return window.requestAnimationFrame(method);
  }

  /// Cancel an operation scheduled by [async].
  void cancelAsync(int id) => window.cancelAnimationFrame(id);

  /// Fire a [CustomEvent] targeting [onNode], or `this` if onNode is not
  /// supplied. Returns the new event.
  CustomEvent fire(String type,
      {Object detail, Node onNode, bool canBubble, bool cancelable}) {
    var node = onNode != null ? onNode : this;
    var event = new CustomEvent(type,
        canBubble: canBubble != null ? canBubble : true,
        cancelable: cancelable != null ? cancelable : true,
        detail: detail);
    node.dispatchEvent(event);
    return event;
  }

  /// Fire an event asynchronously. See [async] and [fire].
  asyncFire(String type, {Object detail, Node toNode, bool canBubble}) {
    // TODO(jmesserly): I'm not sure this method adds much in Dart, it's easy to
    // add "() =>"
    async((x) =>
        fire(type, detail: detail, onNode: toNode, canBubble: canBubble));
  }

  /// Remove [className] from [old], add class to [anew], if they exist.
  void classFollows(Element anew, Element old, String className) {
    if (old != null) {
      old.classes.remove(className);
    }
    if (anew != null) {
      anew.classes.add(className);
    }
  }

  /// Installs external stylesheets and <style> elements with the attribute
  /// polymer-scope='controller' into the scope of element. This is intended
  /// to be called during custom element construction.
  void installControllerStyles() {
    var scope = findStyleScope();
    if (scope != null && !scopeHasNamedStyle(scope, localName)) {
      // allow inherited controller styles
      var decl = _element;
      var cssText = new StringBuffer();
      while (decl != null) {
        cssText.write(decl.cssTextForScope(_STYLE_CONTROLLER_SCOPE));
        decl = decl.superDeclaration;
      }
      if (cssText.isNotEmpty) {
        installScopeCssText('$cssText', scope);
      }
    }
  }

  void installScopeStyle(style, [String name, Node scope]) {
    if (scope == null) scope = findStyleScope();
    if (name == null) name = '';

    if (scope != null && !scopeHasNamedStyle(scope, '$_name$name')) {
      var cssText = new StringBuffer();
      if (style is Iterable) {
        for (var s in style) {
          cssText
            ..writeln(s.text)
            ..writeln();
        }
      } else {
        cssText = (style as Node).text;
      }
      installScopeCssText('$cssText', scope, name);
    }
  }

  void installScopeCssText(String cssText, [Node scope, String name]) {
    if (scope == null) scope = findStyleScope();
    if (name == null) name = '';

    if (scope == null) return;

    if (_hasShadowDomPolyfill) {
      cssText = _shimCssText(cssText, scope is ShadowRoot ? scope.host : null);
    }
    var style = element.cssTextToScopeStyle(cssText, _STYLE_CONTROLLER_SCOPE);
    applyStyleToScope(style, scope);
    // cache that this style has been applied
    styleCacheForScope(scope).add('$_name$name');
  }

  Node findStyleScope([node]) {
    // find the shadow root that contains this element
    var n = node;
    if (n == null) n = this;
    while (n.parentNode != null) {
      n = n.parentNode;
    }
    return n;
  }

  bool scopeHasNamedStyle(Node scope, String name) =>
      styleCacheForScope(scope).contains(name);

  Map _polyfillScopeStyleCache = {};

  Set styleCacheForScope(Node scope) {
    var styles;
    if (_hasShadowDomPolyfill) {
      var name = scope is ShadowRoot
          ? scope.host.localName
          : (scope as Element).localName;
      var styles = _polyfillScopeStyleCache[name];
      if (styles == null) _polyfillScopeStyleCache[name] = styles = new Set();
    } else {
      styles = _scopeStyles[scope];
      if (styles == null) _scopeStyles[scope] = styles = new Set();
    }
    return styles;
  }

  static final _scopeStyles = new Expando();

  static String _shimCssText(String cssText, [Element host]) {
    var name = '';
    var is_ = false;
    if (host != null) {
      name = host.localName;
      is_ = host.attributes.containsKey('is');
    }
    var selector = _ShadowCss.callMethod('makeScopeSelector', [name, is_]);
    return _ShadowCss.callMethod('shimCssText', [cssText, selector]);
  }

  static void applyStyleToScope(StyleElement style, Node scope) {
    if (style == null) return;

    if (scope == document) scope = document.head;

    if (_hasShadowDomPolyfill) scope = document.head;

    // TODO(sorvell): necessary for IE
    // see https://connect.microsoft.com/IE/feedback/details/790212/
    // cloning-a-style-element-and-adding-to-document-produces
    // -unexpected-result#details
    // var clone = style.cloneNode(true);
    var clone = new StyleElement()..text = style.text;

    var attr = style.attributes[_STYLE_SCOPE_ATTRIBUTE];
    if (attr != null) {
      clone.attributes[_STYLE_SCOPE_ATTRIBUTE] = attr;
    }

    // TODO(sorvell): probably too brittle; try to figure out
    // where to put the element.
    var refNode = scope.firstChild;
    if (scope == document.head) {
      var selector = 'style[$_STYLE_SCOPE_ATTRIBUTE]';
      var styleElement = document.head.querySelectorAll(selector);
      if (styleElement.isNotEmpty) {
        refNode = styleElement.last.nextElementSibling;
      }
    }
    scope.insertBefore(clone, refNode);
  }

  /// Invoke [callback] in [wait], unless the job is re-registered,
  /// which resets the timer. If [wait] is not supplied, this will use
  /// [window.requestAnimationFrame] instead of a [Timer].
  ///
  /// For example:
  ///
  ///     _myJob = Polymer.scheduleJob(_myJob, callback);
  ///
  /// Returns the newly created job.
  // Dart note: renamed to scheduleJob to be a bit more consistent with Dart.
  PolymerJob scheduleJob(PolymerJob job, void callback(), [Duration wait]) {
    if (job == null) job = new PolymerJob._();
    // Dart note: made start smarter, so we don't need to call stop.
    return job..start(callback, wait);
  }

  // Deprecated: Please use injectBoundHtml.
  @deprecated
  DocumentFragment injectBoundHTML(String html, [Element element]) =>
      injectBoundHtml(html, element: element);

  /// Inject HTML which contains markup bound to this element into
  /// a target element (replacing target element content).
  DocumentFragment injectBoundHtml(String html, {Element element,
      NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    var template = new TemplateElement()
      ..setInnerHtml(html, validator: validator, treeSanitizer: treeSanitizer);
    var fragment = this.instanceTemplate(template);
    if (element != null) {
      element.text = '';
      element.append(fragment);
    }
    return fragment;
  }
}

// Dart note: this is related to _bindOldStylePublishedProperty. Polymer
// addresses n-way bindings by metaprogramming: redefine the property on the
// PolymerElement instance to always get its value from the model@path. This is
// supported in Dart using a new style of @published property declaration using
// the `readValue` and `writeValue` methods above. In the past we used to work
// around this by listening to changes on both sides and updating the values.
// This object provides the hooks to do this.
// TODO(sigmund,jmesserly): delete after a deprecation period.
class _PolymerBinding extends Bindable {
  final Polymer _target;
  final Symbol _property;
  final Bindable _bindable;
  StreamSubscription _sub;
  Object _lastValue;

  _PolymerBinding(this._target, this._property, this._bindable) {
    _sub = _target.changes.listen(_propertyValueChanged);
    _updateNode(open(_updateNode));
  }

  void _updateNode(newValue) {
    _lastValue = newValue;
    smoke.write(_target, _property, newValue);
    // Note: we don't invoke emitPropertyChangeRecord here because that's
    // done by listening on changes on the PolymerElement.
  }

  void _propertyValueChanged(List<ChangeRecord> records) {
    for (var record in records) {
      if (record is PropertyChangeRecord && record.name == _property) {
        final newValue = smoke.read(_target, _property);
        if (!identical(_lastValue, newValue)) {
          this.value = newValue;
        }
        return;
      }
    }
  }

  open(callback(value)) => _bindable.open(callback);
  get value => _bindable.value;
  set value(newValue) => _bindable.value = newValue;

  void close() {
    if (_sub != null) {
      _sub.cancel();
      _sub = null;
    }
    _bindable.close();
  }
}

// Ported from an inline object in instance/properties.js#bindToAccessor.
class _CloseOnlyBinding extends Bindable {
  final _PropertyAccessor accessor;

  _CloseOnlyBinding(this.accessor);

  open(callback) {}
  get value => null;
  set value(newValue) {}
  deliver() {}

  void close() {
    if (accessor.bindable == null) return;
    accessor.bindable.close();
    accessor.bindable = null;
  }
}

bool _toBoolean(value) => null != value && false != value;

final Logger _observeLog = new Logger('polymer.observe');
final Logger _eventsLog = new Logger('polymer.events');
final Logger _unbindLog = new Logger('polymer.unbind');
final Logger _bindLog = new Logger('polymer.bind');
final Logger _watchLog = new Logger('polymer.watch');
final Logger _readyLog = new Logger('polymer.ready');

final Expando _eventHandledTable = new Expando<Set<Node>>();
