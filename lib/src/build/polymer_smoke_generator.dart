// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that combines multiple Dart script tags into a single one.
library polymer.src.build.polymer_smoke_generator;

import 'dart:async';

import 'package:html/dom.dart' show Document, Element, Text;
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' hide Element;
import 'package:analyzer/src/generated/element.dart' as analyzer show Element;
import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:code_transformers/assets.dart';
import 'package:code_transformers/src/dart_sdk.dart' as dart_sdk;
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:smoke/codegen/generator.dart';
import 'package:smoke/codegen/recorder.dart';
import 'package:code_transformers/resolver.dart';
import 'package:template_binding/src/mustache_tokens.dart' show MustacheTokens;

import 'package:polymer_expressions/expression.dart' as pe;
import 'package:polymer_expressions/parser.dart' as pe;
import 'package:polymer_expressions/visitor.dart' as pe;

import 'package:web_components/build/import_crawler.dart';

import 'common.dart';
import 'messages.dart';

/// Method to generate a bootstrap file for Polymer given a [Transform] and a
/// [Resolver]. This can be used inside any transformer to share the [Resolver]
/// with other steps.
Future<Asset> generatePolymerBootstrap(Transform transform, Resolver resolver,
    AssetId entryPointId, AssetId bootstrapId, Document document,
    TransformOptions options, {AssetId resolveFromId}) {
  return new PolymerSmokeGenerator(
      transform, resolver, entryPointId, bootstrapId, document, options,
      resolveFromId: resolveFromId).apply();
}

class PolymerSmokeGeneratorTransformer extends Transformer
    with PolymerTransformer {
  final Resolvers resolvers;
  final TransformOptions options;

  PolymerSmokeGeneratorTransformer(this.options, {String sdkDir})
      // TODO(sigmund): consider restoring here a resolver that uses the real
      // SDK once the analyzer is lazy and only an resolves what it needs:
      //: resolvers = new Resolvers(sdkDir != null ? sdkDir : dartSdkDirectory);
      : resolvers = new Resolvers.fromMock(dart_sdk.mockSdkSources);

  /// Only run on entry point .html files.
  bool isPrimary(AssetId id) => options.isHtmlEntryPoint(id);

  Future apply(Transform transform) {
    var logger = new BuildLogger(transform,
        convertErrorsToWarnings: !options.releaseMode,
        detailsUri: 'http://goo.gl/5HPeuP');
    var primaryId = transform.primaryInput.id;
    return readPrimaryAsHtml(transform, logger).then((document) {
      var script = document.querySelector('script[type="application/dart"]');
      if (script == null) return null;
      var entryScriptId = uriToAssetId(
          primaryId, script.attributes['src'], logger, script.sourceSpan);
      var bootstrapId = primaryId.addExtension('_bootstrap.dart');
      script.attributes['src'] = path.basename(bootstrapId.path);

      return resolvers.get(transform, [entryScriptId]).then((resolver) {
        return generatePolymerBootstrap(transform, resolver, entryScriptId,
            bootstrapId, document, options).then((bootstrapAsset) {
          transform.addOutput(bootstrapAsset);
          transform
              .addOutput(new Asset.fromString(primaryId, document.outerHtml));
          resolver.release();
        });
      });
    });
  }
}

/// Class which generates the static smoke configuration for polymer.
// TODO(jakemac): Investigate further turning this into an [InitializerPlugin].
// The main difficulty is this actually recognizes any class which extends the
// [PolymerElement] class, not just things annotated with [CustomTag].
class PolymerSmokeGenerator {
  final TransformOptions options;
  final Transform transform;
  final BuildLogger logger;
  final AssetId docId;
  final AssetId bootstrapId;

  /// Id of the Dart script found in the document (can only be one).
  AssetId entryScriptId;

  /// Id of the Dart script to start resolution from.
  AssetId resolveFromId;

  /// HTML document parsed from [docId].
  Document document;

  /// Attributes published on a custom-tag. We make these available via
  /// reflection even if @published was not used.
  final Map<String, List<String>> publishedAttributes = {};

  /// Resolved types used for analyzing the user's sources and generating code.
  _ResolvedTypes types;

  /// The resolver instance associated with a single run of this transformer.
  Resolver resolver;

  /// Code generator used to create the static initialization for smoke.
  final generator = new SmokeCodeGenerator();

  _SubExpressionVisitor expressionVisitor;

  PolymerSmokeGenerator(Transform transform, Resolver resolver,
      this.entryScriptId, this.bootstrapId, this.document, options,
      {this.resolveFromId})
      : transform = transform,
        options = options,
        logger = new BuildLogger(transform,
            convertErrorsToWarnings: !options.releaseMode,
            detailsUri: 'http://goo.gl/5HPeuP'),
        docId = transform.primaryInput.id,
        resolver = resolver {
    _ResolvedTypes.logger = logger;
    types = new _ResolvedTypes(resolver);
    if (resolveFromId == null) resolveFromId = entryScriptId;
  }

  Future<Asset> apply() {
    return _extractUsesOfMirrors().then((_) {
      var bootstrapAsset = _buildBootstrap();
      _modifyDocument();

      // Write out the logs collected by our [BuildLogger].
      if (options.injectBuildLogsInOutput) {
        return logger.writeOutput().then((_) => bootstrapAsset);
      }
      return bootstrapAsset;
    });
  }

  /// Inspects the entire program to find out anything that polymer accesses
  /// using mirrors and produces static information that can be used to replace
  /// the mirror-based loader and the uses of mirrors through the `smoke`
  /// package. This includes:
  ///
  ///   * visiting polymer-expressions to extract getters and setters,
  ///   * looking for published fields of custom elements, and
  ///   * looking for event handlers and callbacks of change notifications.
  ///
  Future _extractUsesOfMirrors() {
    // Generate getters and setters needed to evaluate polymer expressions, and
    // extract information about published attributes.
    expressionVisitor = new _SubExpressionVisitor(generator, logger);

    return new ImportCrawler(transform, transform.primaryInput.id, logger,
        primaryDocument: document).crawlImports().then((documentData) {
      for (var data in documentData.values) {
        new _HtmlExtractor(
                logger, generator, publishedAttributes, expressionVisitor)
            .visit(data.document);
      }

      // Create a recorder that uses analyzer data to feed data to [generator].
      var recorder = new Recorder(generator,
          (lib) => resolver.getImportUri(lib, from: bootstrapId).toString());

      // Process all classes to include special fields and methods in custom
      // element classes.
      _visitLibraries(resolver.getLibrary(resolveFromId), recorder);
    });
  }

  _visitLibraries(LibraryElement library, Recorder recorder,
      [Set<LibraryElement> librariesSeen, Set<ClassElement> classesSeen]) {
    if (librariesSeen == null) librariesSeen = new Set<LibraryElement>();
    librariesSeen.add(library);

    // Visit all our dependencies.
    for (var importedLibrary in _libraryDependencies(library)) {
      // Don't include anything from the sdk.
      if (importedLibrary.isInSdk) continue;
      if (librariesSeen.contains(importedLibrary)) continue;
      _visitLibraries(importedLibrary, recorder, librariesSeen, classesSeen);
    }

    // After visiting dependencies, then visit classes in this library.
    if (classesSeen == null) classesSeen = new Set<ClassElement>();
    var classes = _visibleClassesOf(library);
    for (var clazz in classes) {
      _processClass(clazz, recorder);
    }
  }

  Iterable<LibraryElement> _libraryDependencies(LibraryElement library) {
    getLibrary(UriReferencedElement element) {
      if (element is ImportElement) return element.importedLibrary;
      if (element is ExportElement) return element.exportedLibrary;
    }

    return (new List.from(library.imports)..addAll(library.exports))
        .map(getLibrary);
  }

  /// Process a class ([cls]). If it contains an appropriate [CustomTag]
  /// annotation, we make sure to include everything that might be accessed or
  /// queried from them using the smoke package. In particular, polymer uses
  /// smoke for the following:
  ///    * invoke #registerCallback on custom elements classes, if present.
  ///    * query for methods ending in `*Changed`.
  ///    * query for methods with the `@ObserveProperty` annotation.
  ///    * query for non-final properties labeled with `@published`.
  ///    * read declarations of properties named in the `attributes` attribute.
  ///    * read/write the value of published properties .
  ///    * invoke methods in event handlers.
  _processClass(ClassElement cls, Recorder recorder) {
    if (!_hasPolymerMixin(cls)) return;
    if (cls.node is! ClassDeclaration) return;
    var node = cls.node as ClassDeclaration;

    // Check whether the class has a @CustomTag annotation. Typically we expect
    // a single @CustomTag, but it's possible to have several.
    var tagNames = [];
    for (var meta in node.metadata) {
      var tagName = _extractTagName(meta, cls);
      if (tagName != null) tagNames.add(tagName);
    }

    if (cls.isPrivate && tagNames.isNotEmpty) {
      var name = tagNames.first;
      logger.error(PRIVATE_CUSTOM_TAG.create({'name': name, 'class': cls.name}),
          span: _spanForNode(cls, node.name));
      return;
    }

    // Include #registerCallback if it exists. Note that by default lookupMember
    // and query will also add the corresponding getters and setters.
    recorder.lookupMember(cls, 'registerCallback');

    // Include methods that end with *Changed.
    recorder.runQuery(cls, new QueryOptions(
        includeFields: false,
        includeProperties: false,
        includeInherited: true,
        includeMethods: true,
        includeUpTo: types.htmlElementElement,
        matches: (n) => n.endsWith('Changed') && n != 'attributeChanged'));

    // Include methods marked with @ObserveProperty.
    recorder.runQuery(cls, new QueryOptions(
        includeFields: false,
        includeProperties: false,
        includeInherited: true,
        includeMethods: true,
        includeUpTo: types.htmlElementElement,
        withAnnotations: [types.observePropertyElement]));

    // Include @published and @observable properties.
    // Symbols in @published are used when resolving bindings on published
    // attributes, symbols for @observable are used via path observers when
    // implementing *Changed an @ObserveProperty.
    // TODO(sigmund): consider including only those symbols mentioned in
    // *Changed and @ObserveProperty instead.
    recorder.runQuery(cls, new QueryOptions(
        includeUpTo: types.htmlElementElement,
        withAnnotations: [
      types.publishedElement,
      types.observableElement,
      types.computedPropertyElement
    ]));

    // Include @ComputedProperty and process their expressions
    var computed = [];
    recorder.runQuery(cls, new QueryOptions(
        includeUpTo: types.htmlElementElement,
        withAnnotations: [types.computedPropertyElement]), results: computed);
    _processComputedExpressions(computed);

    for (var tagName in tagNames) {
      // Include also properties published via the `attributes` attribute.
      var attrs = publishedAttributes[tagName];
      if (attrs == null) continue;
      for (var attr in attrs) {
        recorder.lookupMember(cls, attr,
            recursive: true, includeUpTo: types.htmlElementElement);
      }
    }
  }

  /// Determines if [cls] or a supertype has a mixin of the Polymer class.
  bool _hasPolymerMixin(ClassElement cls) {
    while (cls != types.htmlElementElement) {
      for (var m in cls.mixins) {
        if (m.element == types.polymerClassElement) return true;
      }
      if (cls.supertype == null) return false;
      cls = cls.supertype.element;
    }
    return false;
  }

  /// If [meta] is [CustomTag], extract the name associated with the tag.
  String _extractTagName(Annotation meta, ClassElement cls) {
    if (meta.element != types.customTagConstructor) return null;
    return _extractFirstAnnotationArgument(meta, 'CustomTag', cls);
  }

  /// Extract the first argument of an annotation and validate that it's type is
  /// String. For instance, return "bar" from `@Foo("bar")`.
  String _extractFirstAnnotationArgument(
      Annotation meta, String name, analyzer.Element context) {

    // Read argument from the AST
    var args = meta.arguments.arguments;
    if (args == null || args.length == 0) {
      logger.warning(MISSING_ANNOTATION_ARGUMENT.create({'name': name}),
          span: _spanForNode(context, meta));
      return null;
    }

    var lib = context;
    while (lib is! LibraryElement) lib = lib.enclosingElement;
    var res = resolver.evaluateConstant(lib, args[0]);
    if (!res.isValid || res.value.type != types.stringType) {
      logger.warning(INVALID_ANNOTATION_ARGUMENT.create({'name': name}),
          span: _spanForNode(context, args[0]));
      return null;
    }
    return res.value.stringValue;
  }

  /// Process members that are annotated with `@ComputedProperty` and records
  /// the accessors of their expressions.
  _processComputedExpressions(List<analyzer.Element> computed) {
    var constructor = types.computedPropertyElement.constructors.first;
    for (var member in computed) {
      for (var meta in member.node.metadata) {
        if (meta.element != constructor) continue;
        var expr =
            _extractFirstAnnotationArgument(meta, 'ComputedProperty', member);
        if (expr == null) continue;
        expressionVisitor.run(pe.parse(expr), true,
            _spanForNode(member.enclosingElement, meta.arguments.arguments[0]));
      }
    }
  }

  // Builds the bootstrap Dart file asset.
  Asset _buildBootstrap() {
    StringBuffer code = new StringBuffer()..writeln(MAIN_HEADER);

    // TODO(jakemac): Inject this at some other stage.
    // https://github.com/dart-lang/polymer-dart/issues/22
    if (options.injectBuildLogsInOutput) {
      code.writeln("import 'package:polymer/src/build/log_injector.dart';");
    }

    var entryScriptUrl = assetUrlFor(entryScriptId, bootstrapId, logger);
    code.writeln("import '$entryScriptUrl' as i0;");

    // Include smoke initialization.
    generator.writeImports(code);
    generator.writeTopLevelDeclarations(code);
    code.writeln('\nmain() {');
    code.write('  useGeneratedCode(');
    generator.writeStaticConfiguration(code);
    code.writeln(');');

    // TODO(jakemac): Inject this at some other stage.
    // https://github.com/dart-lang/polymer-dart/issues/22
    if (options.injectBuildLogsInOutput) {
      var buildUrl = "${path.basename(docId.path)}$LOG_EXTENSION";
      code.writeln("  new LogInjector().injectLogsFromUrl('$buildUrl');");
    }

    code.writeln('  configureForDeployment();');
    code.writeln('  return i0.main();');

    // End of main().
    code.writeln('}');
    return new Asset.fromString(bootstrapId, code.toString());
  }

  // Add the styles for the logger widget.
  // TODO(jakemac): Inject this at some other stage.
  // https://github.com/dart-lang/polymer-dart/issues/22
  void _modifyDocument() {
    if (options.injectBuildLogsInOutput) {
      document.head.append(parseFragment(
          '<link rel="stylesheet" type="text/css"'
          ' href="packages/polymer/src/build/log_injector.css">'));
    }
  }

  _spanForNode(analyzer.Element context, AstNode node) {
    var file = resolver.getSourceFile(context);
    return file.span(node.offset, node.end);
  }
}

const MAIN_HEADER = """
library app_bootstrap;

import 'package:polymer/polymer.dart';
""";

/// An html visitor that:
///   * finds all polymer expressions and records the getters and setters that
///     will be needed to evaluate them at runtime.
///   * extracts all attributes declared in the `attribute` attributes of
///     polymer elements.
class _HtmlExtractor extends TreeVisitor {
  final Map<String, List<String>> publishedAttributes;
  final SmokeCodeGenerator generator;
  final _SubExpressionVisitor expressionVisitor;
  final BuildLogger logger;
  bool _inTemplate = false;
  bool _inPolymerJs = false;

  _HtmlExtractor(this.logger, this.generator, this.publishedAttributes,
      this.expressionVisitor);

  void visitElement(Element node) {
    if (_inTemplate) _processNormalElement(node);
    var lastInPolymerJs = _inPolymerJs;
    if (node.localName == 'polymer-element') {
      // Detect Polymer JS elements, the current logic is any element with only
      // non-Dart script tags.
      var scripts = node.querySelectorAll('script');
      _inPolymerJs = scripts.isNotEmpty &&
          scripts.every((s) => s.attributes['type'] != 'application/dart');
      _processPolymerElement(node);
      _processNormalElement(node);
    }

    if (node.localName == 'template') {
      var last = _inTemplate;
      _inTemplate = true;
      super.visitElement(node);
      _inTemplate = last;
    } else {
      super.visitElement(node);
    }
    _inPolymerJs = lastInPolymerJs;
  }

  void visitText(Text node) {
    // Nothing here applies if inside a polymer js element
    if (!_inTemplate || _inPolymerJs) return;
    var bindings = _Mustaches.parse(node.data);
    if (bindings == null) return;
    for (var e in bindings.expressions) {
      _addExpression(e, false, false, node.sourceSpan);
    }
  }

  /// Registers getters and setters for all published attributes.
  void _processPolymerElement(Element node) {
    // Nothing here applies if inside a polymer js element
    if (_inPolymerJs) return;

    var tagName = node.attributes['name'];
    var value = node.attributes['attributes'];
    if (value != null) {
      publishedAttributes[tagName] =
          value.split(ATTRIBUTES_REGEX).map((a) => a.trim()).toList();
    }
  }

  /// Produces warnings for misuses of on-foo event handlers, and for instanting
  /// custom tags incorrectly.
  void _processNormalElement(Element node) {
    // Nothing here applies if inside a polymer js element
    if (_inPolymerJs) return;

    var tag = node.localName;
    var isCustomTag = isCustomTagName(tag) || node.attributes['is'] != null;

    // Event handlers only allowed inside polymer-elements
    node.attributes.forEach((name, value) {
      var bindings = _Mustaches.parse(value);
      if (bindings == null) return;
      var isEvent = false;
      var isTwoWay = false;
      if (name is String) {
        name = name.toLowerCase();
        isEvent = name.startsWith('on-');
        isTwoWay = !isEvent &&
            bindings.isWhole &&
            (isCustomTag ||
                tag == 'input' && (name == 'value' || name == 'checked') ||
                tag == 'select' &&
                    (name == 'selectedindex' || name == 'value') ||
                tag == 'textarea' && name == 'value');
      }
      for (var exp in bindings.expressions) {
        _addExpression(exp, isEvent, isTwoWay, node.sourceSpan);
      }
    });
  }

  void _addExpression(
      String stringExpression, bool inEvent, bool isTwoWay, SourceSpan span) {
    if (inEvent) {
      if (stringExpression.startsWith('@')) {
        logger.warning(AT_EXPRESSION_REMOVED, span: span);
        return;
      }

      if (stringExpression == '') return;
      if (stringExpression.startsWith('_')) {
        logger.warning(NO_PRIVATE_EVENT_HANDLERS, span: span);
        return;
      }
      generator.addGetter(stringExpression);
      generator.addSymbol(stringExpression);
    }
    expressionVisitor.run(pe.parse(stringExpression), isTwoWay, span);
  }
}

/// A polymer-expression visitor that records every getter and setter that will
/// be needed to evaluate a single expression at runtime.
class _SubExpressionVisitor extends pe.RecursiveVisitor {
  final SmokeCodeGenerator generator;
  final BuildLogger logger;
  bool _includeSetter;
  SourceSpan _currentSpan;

  _SubExpressionVisitor(this.generator, this.logger);

  /// Visit [exp], and record getters and setters that are needed in order to
  /// evaluate it at runtime. [includeSetter] is only true if this expression
  /// occured in a context where it could be updated, for example in two-way
  /// bindings such as `<input value={{exp}}>`.
  void run(pe.Expression exp, bool includeSetter, span) {
    _currentSpan = span;
    _includeSetter = includeSetter;
    visit(exp);
  }

  /// Adds a getter and symbol for [name], and optionally a setter.
  _add(String name) {
    if (name.startsWith('_')) {
      logger.warning(NO_PRIVATE_SYMBOLS_IN_BINDINGS, span: _currentSpan);
      return;
    }
    generator.addGetter(name);
    generator.addSymbol(name);
    if (_includeSetter) generator.addSetter(name);
  }

  void preVisitExpression(e) {
    // For two-way bindings the outermost expression may be updated, so we need
    // both the getter and the setter, but we only need the getter for
    // subexpressions. We exclude setters as soon as we go deeper in the tree,
    // except when we see a filter (that can potentially be a two-way
    // transformer).
    if (e is pe.BinaryOperator && e.operator == '|') return;
    _includeSetter = false;
  }

  visitIdentifier(pe.Identifier e) {
    if (e.value != 'this') _add(e.value);
    super.visitIdentifier(e);
  }

  visitGetter(pe.Getter e) {
    _add(e.name);
    super.visitGetter(e);
  }

  visitInvoke(pe.Invoke e) {
    _includeSetter = false; // Invoke is only valid as an r-value.
    if (e.method != null) _add(e.method);
    super.visitInvoke(e);
  }
}

/// Parses and collects information about bindings found in polymer templates.
class _Mustaches {
  /// Each expression that appears within `{{...}}` and `[[...]]`.
  final List<String> expressions;

  /// Whether the whole text returned by [parse] was a single expression.
  final bool isWhole;

  _Mustaches(this.isWhole, this.expressions);

  static _Mustaches parse(String text) {
    if (text == null || text.isEmpty) return null;
    // Use template-binding's parser, but provide a delegate function factory to
    // save the expressions without parsing them as [PropertyPath]s.
    var tokens = MustacheTokens.parse(text, (s) => () => s);
    if (tokens == null) return null;
    var length = tokens.length;
    bool isWhole =
        length == 1 && tokens.getText(length) == '' && tokens.getText(0) == '';
    var expressions = new List(length);
    for (int i = 0; i < length; i++) {
      expressions[i] = tokens.getPrepareBinding(i)();
    }
    return new _Mustaches(isWhole, expressions);
  }
}

/// Holds types that are used in queries
class _ResolvedTypes {
  /// Element representing `HtmlElement`.
  final ClassElement htmlElementElement;

  /// Element representing `String`.
  final InterfaceType stringType;

  /// Element representing `Polymer`.
  final ClassElement polymerClassElement;

  /// Element representing the constructor of `@CustomTag`.
  final ConstructorElement customTagConstructor;

  /// Element representing the type of `@published`.
  final ClassElement publishedElement;

  /// Element representing the type of `@observable`.
  final ClassElement observableElement;

  /// Element representing the type of `@ObserveProperty`.
  final ClassElement observePropertyElement;

  /// Element representing the type of `@ComputedProperty`.
  final ClassElement computedPropertyElement;

  /// Logger for reporting errors.
  static BuildLogger logger;

  factory _ResolvedTypes(Resolver resolver) {
    var coreLib = resolver.getLibraryByUri(Uri.parse('dart:core'));
    // coreLib should never be null, its ok to throw if this fails.
    var stringType = _lookupType(coreLib, 'String').type;

    // Load class elements that are used in queries for codegen.
    var polymerLib =
        resolver.getLibrary(new AssetId('polymer', 'lib/polymer.dart'));
    if (polymerLib == null) {
      _definitionError('polymer');
      return new _ResolvedTypes.internal(
          null, stringType, null, null, null, null, null, null);
    }

    var htmlLib = resolver.getLibraryByUri(Uri.parse('dart:html'));
    var observeLib =
        resolver.getLibrary(new AssetId('observe', 'lib/src/metadata.dart'));

    var customTagConstructor =
        _lookupType(polymerLib, 'CustomTag').constructors.first;
    var publishedElement = _lookupType(polymerLib, 'PublishedProperty');
    var observePropertyElement = _lookupType(polymerLib, 'ObserveProperty');
    var computedPropertyElement = _lookupType(polymerLib, 'ComputedProperty');
    var polymerClassElement = _lookupType(polymerLib, 'Polymer');
    var observableElement = _lookupType(observeLib, 'ObservableProperty');
    var htmlElementElement = _lookupType(htmlLib, 'HtmlElement');

    return new _ResolvedTypes.internal(htmlElementElement, stringType,
        polymerClassElement, customTagConstructor, publishedElement,
        observableElement, observePropertyElement, computedPropertyElement);
  }

  _ResolvedTypes.internal(this.htmlElementElement, this.stringType,
      this.polymerClassElement, this.customTagConstructor,
      this.publishedElement, this.observableElement,
      this.observePropertyElement, this.computedPropertyElement);

  static _lookupType(LibraryElement lib, String typeName) {
    var result = lib.getType(typeName);
    if (result == null) _definitionError(typeName);
    return result;
  }

  static _definitionError(name) {
    var message = MISSING_POLYMER_DART;
    if (logger != null) {
      logger.warning(message);
    } else {
      throw new StateError(message.snippet);
    }
  }
}

/// Retrieves all classes that are visible if you were to import [lib]. This
/// includes exported classes from other libraries.
List<ClassElement> _visibleClassesOf(LibraryElement lib) {
  var result = [];
  result.addAll(lib.units.expand((u) => u.types));
  for (var e in lib.exports) {
    var exported = e.exportedLibrary.units.expand((u) => u.types).toList();
    _filter(exported, e.combinators);
    result.addAll(exported);
  }
  return result;
}

/// Retrieves all top-level methods that are visible if you were to import
/// [lib]. This includes exported methods from other libraries too.
List<FunctionElement> _visibleTopLevelMethodsOf(LibraryElement lib) {
  var result = [];
  result.addAll(lib.units.expand((u) => u.functions));
  for (var e in lib.exports) {
    var exported = e.exportedLibrary.units.expand((u) => u.functions).toList();
    _filter(exported, e.combinators);
    result.addAll(exported);
  }
  return result;
}

/// Filters [elements] that come from an export, according to its show/hide
/// combinators. This modifies [elements] in place.
void _filter(
    List<analyzer.Element> elements, List<NamespaceCombinator> combinators) {
  for (var c in combinators) {
    if (c is ShowElementCombinator) {
      var show = c.shownNames.toSet();
      elements.retainWhere((e) => show.contains(e.displayName));
    } else if (c is HideElementCombinator) {
      var hide = c.hiddenNames.toSet();
      elements.removeWhere((e) => hide.contains(e.displayName));
    }
  }
}
