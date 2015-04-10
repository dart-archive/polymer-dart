// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer that finalizes an html file for deployment:
///   - Extracts inline js scripts in csp mode.
///   - Inlines css files into the document.
///   - Validates polymer-element templates.
library polymer.src.build.html_finalizer;

import 'dart:async';
import 'dart:collection' show LinkedHashSet;

import 'package:barback/barback.dart';
import 'package:code_transformers/assets.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:path/path.dart' as path;
import 'package:html/dom.dart'
    show Document, DocumentFragment, Element, Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;
import 'package:source_span/source_span.dart';

import 'common.dart';
import 'messages.dart';

/// Inlines css files and extracts inline js scripts into files if in csp mode.
// TODO(jakemac): Move to a different package. Will need to break out the
// binding-specific logic when this happens (add it to the linter?).
class _HtmlFinalizer extends PolymerTransformer {
  final TransformOptions options;
  final Transform transform;
  final BuildLogger logger;
  final AssetId docId;
  final seen = new Set<AssetId>();
  final scriptIds = new LinkedHashSet<AssetId>();
  final inlinedStylesheetIds = new Set<AssetId>();
  final extractedFiles = new Set<AssetId>();

  /// The number of extracted inline Dart scripts. Used as a counter to give
  /// unique-ish filenames.
  int inlineScriptCounter = 0;

  _HtmlFinalizer(TransformOptions options, Transform transform)
      : options = options,
        transform = transform,
        logger = new BuildLogger(transform,
            convertErrorsToWarnings: !options.releaseMode,
            detailsUri: 'http://goo.gl/5HPeuP'),
        docId = transform.primaryInput.id;

  Future apply() {
    seen.add(docId);

    Document document;
    bool changed = false;

    return readPrimaryAsHtml(transform, logger).then((doc) {
      document = doc;
      new _UrlAttributeValidator(docId, logger).visit(document);

      changed = _extractScripts(document) || changed;

      return _inlineCss(document);
    }).then((cssInlined) {
      changed = changed || cssInlined;

      var output = transform.primaryInput;
      if (changed) output = new Asset.fromString(docId, document.outerHtml);
      transform.addOutput(output);

      // Write out the logs collected by our [BuildLogger].
      if (options.injectBuildLogsInOutput) {
        return logger.writeOutput();
      }
    });
  }

  /// Inlines any css files found into document. Returns a [bool] indicating
  /// whether or not the document was modified.
  Future<bool> _inlineCss(Document document) {
    bool changed = false;

    // Note: we need to preserve the import order in the generated output.
    var tags = document.querySelectorAll('link[rel="stylesheet"]');
    return Future.forEach(tags, (Element tag) {
      var href = tag.attributes['href'];
      var id = uriToAssetId(docId, href, logger, tag.sourceSpan,
          errorOnAbsolute: false);
      if (id == null) return null;
      if (!options.shouldInlineStylesheet(id)) return null;

      changed = true;
      if (inlinedStylesheetIds.contains(id) &&
          !options.stylesheetInliningIsOverridden(id)) {
        logger.warning(CSS_FILE_INLINED_MULTIPLE_TIMES.create({'url': id.path}),
            span: tag.sourceSpan);
      }
      inlinedStylesheetIds.add(id);
      return _inlineStylesheet(id, tag);
    }).then((_) => changed);
  }

  /// Inlines a single css file by replacing [link] with an inline style tag.
  Future _inlineStylesheet(AssetId id, Element link) {
    return transform.readInputAsString(id).catchError((error) {
      // TODO(jakemac): Move this warning to the linter once we can make it run
      // always (see http://dartbug.com/17199). Then hide this error and replace
      // with a comment pointing to the linter error (so we don't double warn).
      logger.warning(INLINE_STYLE_FAIL.create({'error': error}),
          span: link.sourceSpan);
    }).then((css) {
      if (css == null) return null;
      css = new _UrlNormalizer(transform, id, logger).visitCss(css);
      var styleElement = new Element.tag('style')..text = css;
      // Copy over the extra attributes from the link tag to the style tag.
      // This adds support for no-shim, shim-shadowdom, etc.
      link.attributes.forEach((key, value) {
        if (!IGNORED_LINKED_STYLE_ATTRS.contains(key)) {
          styleElement.attributes[key] = value;
        }
      });
      link.replaceWith(styleElement);
    });
  }

  /// Splits inline js scripts into their own files in csp mode.
  bool _extractScripts(Document doc) {
    if (!options.contentSecurityPolicy) return false;

    bool changed = false;
    for (var script in doc.querySelectorAll('script')) {
      var src = script.attributes['src'];
      if (src != null) continue;

      var type = script.attributes['type'];
      if (type == TYPE_DART) continue;

      var extension = 'js';
      final filename = path.url.basename(docId.path);
      final count = inlineScriptCounter++;
      var code = script.text;
      // TODO(sigmund): ensure this path is unique (dartbug.com/12618).
      script.attributes['src'] = src = '$filename.$count.$extension';
      script.text = '';
      changed = true;

      var newId = docId.addExtension('.$count.$extension');
      extractedFiles.add(newId);
      transform.addOutput(new Asset.fromString(newId, code));
    }
    return changed;
  }
}

/// Finalizes a single html document for deployment.
class HtmlFinalizer extends Transformer {
  final TransformOptions options;

  HtmlFinalizer(this.options);

  /// Only run on entry point .html files.
  bool isPrimary(AssetId id) => options.isHtmlEntryPoint(id);

  Future apply(Transform transform) =>
      new _HtmlFinalizer(options, transform).apply();
}

const TYPE_DART = 'application/dart';
const TYPE_JS = 'text/javascript';

/// Internally adjusts urls in the html that we are about to inline.
class _UrlNormalizer {
  final Transform transform;

  /// Asset where the original content (and original url) was found.
  final AssetId sourceId;

  /// Path to the top level folder relative to the transform primaryInput.
  /// This should just be some arbitrary # of ../'s.
  final String topLevelPath;

  /// Whether or not the normalizer has changed something in the tree.
  bool changed = false;

  final BuildLogger logger;

  _UrlNormalizer(transform, this.sourceId, this.logger)
      : transform = transform,
        topLevelPath = '../' *
            (path.url.split(transform.primaryInput.id.path).length - 2);

  static final _URL = new RegExp(r'url\(([^)]*)\)', multiLine: true);
  static final _QUOTE = new RegExp('["\']', multiLine: true);

  /// Visit the CSS text and replace any relative URLs so we can inline it.
  // Ported from:
  // https://github.com/Polymer/vulcanize/blob/c14f63696797cda18dc3d372b78aa3378acc691f/lib/vulcan.js#L149
  // TODO(jmesserly): use csslib here instead? Parsing with RegEx is sadness.
  // Maybe it's reliable enough for finding URLs in CSS? I'm not sure.
  String visitCss(String cssText) {
    var url = spanUrlFor(sourceId, transform, logger);
    var src = new SourceFile(cssText, url: url);
    return cssText.replaceAllMapped(_URL, (match) {
      // Extract the URL, without any surrounding quotes.
      var span = src.span(match.start, match.end);
      var href = match[1].replaceAll(_QUOTE, '');
      href = _newUrl(href, span);
      return 'url($href)';
    });
  }

  String _newUrl(String href, SourceSpan span) {
    var uri = Uri.parse(href);
    if (uri.isAbsolute) return href;
    if (!uri.scheme.isEmpty) return href;
    if (!uri.host.isEmpty) return href;
    if (uri.path.isEmpty) return href; // Implies standalone ? or # in URI.
    if (path.isAbsolute(href)) return href;

    var id = uriToAssetId(sourceId, href, logger, span);
    if (id == null) return href;
    var primaryId = transform.primaryInput.id;

    if (id.path.startsWith('lib/')) {
      return '${topLevelPath}packages/${id.package}/${id.path.substring(4)}';
    }

    if (id.path.startsWith('asset/')) {
      return '${topLevelPath}assets/${id.package}/${id.path.substring(6)}';
    }

    if (primaryId.package != id.package) {
      // Technically we shouldn't get there
      logger.error(INTERNAL_ERROR_DONT_KNOW_HOW_TO_IMPORT
              .create({'target': id, 'source': primaryId, 'extra': ''}),
          span: span);
      return href;
    }

    var builder = path.url;
    return builder.relative(builder.join('/', id.path),
        from: builder.join('/', builder.dirname(primaryId.path)));
  }
}

/// Validates url-like attributes and throws warnings as appropriate.
/// TODO(jakemac): Move to the linter.
class _UrlAttributeValidator extends TreeVisitor {
  /// Asset where the original content (and original url) was found.
  final AssetId sourceId;

  final BuildLogger logger;

  _UrlAttributeValidator(this.sourceId, this.logger);

  visit(Node node) {
    return super.visit(node);
  }

  visitElement(Element node) {
    // TODO(jakemac): Support custom elements that extend html elements which
    // have url-like attributes. This probably means keeping a list of which
    // html elements support each url-like attribute.
    if (!isCustomTagName(node.localName)) {
      node.attributes.forEach((name, value) {
        if (_urlAttributes.contains(name)) {
          if (!name.startsWith('_') && value.contains(_BINDING_REGEX)) {
            logger.warning(USE_UNDERSCORE_PREFIX.create({'name': name}),
                span: node.sourceSpan, asset: sourceId);
          } else if (name.startsWith('_') && !value.contains(_BINDING_REGEX)) {
            logger.warning(
                DONT_USE_UNDERSCORE_PREFIX.create({'name': name.substring(1)}),
                span: node.sourceSpan, asset: sourceId);
          }
        }
      });
    }
    return super.visitElement(node);
  }
}

/// HTML attributes that expect a URL value.
/// <http://dev.w3.org/html5/spec/section-index.html#attributes-1>
///
/// Every one of these attributes is a URL in every context where it is used in
/// the DOM. The comments show every DOM element where an attribute can be used.
///
/// The _* version of each attribute is also supported, see http://goo.gl/5av8cU
const _urlAttributes = const [
  // in form
  'action',
  '_action',
  // in body
  'background',
  '_background',
  // in blockquote, del, ins, q
  'cite',
  '_cite',
  // in object
  'data',
  '_data',
  // in button, input
  'formaction',
  '_formaction',
  // in a, area, link, base, command
  'href',
  '_href',
  // in command
  'icon',
  '_icon',
  // in html
  'manifest',
  '_manifest',
  // in video
  'poster',
  '_poster',
  // in audio, embed, iframe, img, input, script, source, track, video
  'src',
  '_src',
];

/// When inlining <link rel="stylesheet"> tags copy over all attributes to the
/// style tag except these ones.
const IGNORED_LINKED_STYLE_ATTRS = const [
  'charset',
  'href',
  'href-lang',
  'rel',
  'rev'
];

/// Global RegExp objects.
final _BINDING_REGEX = new RegExp(r'(({{.*}})|(\[\[.*\]\]))');
