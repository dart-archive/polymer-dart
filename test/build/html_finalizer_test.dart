// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.html_finalizer_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/html_finalizer.dart';
import 'package:polymer/src/build/messages.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'common.dart';

final phases = [[new HtmlFinalizer(new TransformOptions())]];

void main() {
  useCompactVMConfiguration();
  group('csp', cspTests);
  group('rel=stylesheet', stylesheetTests);
  group('url attributes', urlAttributeTests);
}

cspTests() {
  final cspPhases =
      [[new HtmlFinalizer(new TransformOptions(contentSecurityPolicy: true))]];
  testPhases('extract Js scripts in CSP mode', cspPhases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<script type="text/javascript">/*first*/</script>'
        '<script src="second.js"></script>'
        '<script>/*third*/</script>'
        '<script type="application/dart">/*fourth*/</script>'
        '</head><body>'
        '<script>/*fifth*/</script>'
        '</body></html>',
    'a|web/second.js': '/*second*/'
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<script type="text/javascript" src="test.html.0.js"></script>'
        '<script src="second.js"></script>'
        '<script src="test.html.1.js"></script>'
        '<script type="application/dart">/*fourth*/</script>'
        '</head><body>'
        '<script src="test.html.2.js"></script>'
        '</body></html>',
    'a|web/test.html.0.js': '/*first*/',
    'a|web/test.html.1.js': '/*third*/',
    'a|web/test.html.2.js': '/*fifth*/',
  });
}

void stylesheetTests() {
  testPhases('empty stylesheet', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="">' // empty href
        '</head></html>',
    'a|web/test2.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet">' // no href
        '</head></html>',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="">' // empty href
        '</head></html>',
    'a|web/test2.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet">' // no href
        '</head></html>',
  });

  testPhases('shallow, inlines css', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="test2.css">'
        '</head></html>',
    'a|web/test2.css': 'h1 { font-size: 70px; }',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<style>h1 { font-size: 70px; }</style>'
        '</head><body>'
        '</body></html>',
  });

  testPhases('deep, inlines css', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="assets/b/test3.css">'
        '</head></html>',
    'b|asset/test3.css':
        'body {\n  background: #eaeaea url("../../assets/b/test4.png");\n}\n'
        '.foo {\n  background: url("../../packages/c/test5.png");\n}',
    'b|asset/test4.png': 'PNG',
    'c|lib/test5.png': 'PNG',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<style>'
        'body {\n  background: #eaeaea url(assets/b/test4.png);\n}\n'
        '.foo {\n  background: url(packages/c/test5.png);\n}'
        '</style>'
        '</head><body>'
        '</body></html>',
  });

  testPhases('shallow, inlines css and preserves order', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<style>.first { color: black }</style>'
        '<link rel="stylesheet" href="test2.css">'
        '<style>.second { color: black }</style>'
        '</head></html>',
    'a|web/test2.css': 'h1 { font-size: 70px; }',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<style>.first { color: black }</style>'
        '<style>h1 { font-size: 70px; }</style>'
        '<style>.second { color: black }</style>'
        '</head><body>'
        '</body></html>',
  });

  testPhases('inlined tags keep original attributes', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="foo.css" no-shim>'
        '<link rel="stylesheet" href="bar.css" shim-shadow foo>'
        '</head></html>',
    'a|web/foo.css': 'h1 { font-size: 70px; }',
    'a|web/bar.css': 'h2 { font-size: 35px; }',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<style no-shim="">h1 { font-size: 70px; }</style>'
        '<style shim-shadow="" foo="">h2 { font-size: 35px; }</style>'
        '</head><body>'
        '</body></html>',
  });

  testPhases('can configure default stylesheet inlining', [
    [
      new HtmlFinalizer(
          new TransformOptions(inlineStylesheets: {'default': false}))
    ]
  ], {
    'a|web/test.html': '<!DOCTYPE html><html><head></head><body>'
        '<link rel="stylesheet" href="foo.css">'
        '</body></html>',
    'a|web/foo.css': 'h1 { font-size: 70px; }',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head></head><body>'
        '<link rel="stylesheet" href="foo.css">'
        '</body></html>',
  });

  testPhases('can override default stylesheet inlining', [
    [
      new HtmlFinalizer(new TransformOptions(
          inlineStylesheets: {
        'default': false,
        'web/foo.css': true,
        'b|lib/baz.css': true,
      }))
    ]
  ], {
    'a|web/test.html': '<!DOCTYPE html><html><head></head><body>'
        '<link rel="stylesheet" href="bar.css">'
        '<link rel="stylesheet" href="foo.css">'
        '<link rel="stylesheet" href="packages/b/baz.css">'
        '<link rel="stylesheet" href="packages/c/buz.css">'
        '</body></html>',
    'a|web/foo.css': 'h1 { font-size: 70px; }',
    'a|web/bar.css': 'h1 { font-size: 35px; }',
    'b|lib/baz.css': 'h1 { font-size: 20px; }',
    'c|lib/buz.css': 'h1 { font-size: 10px; }',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head></head><body>'
        '<link rel="stylesheet" href="bar.css">'
        '<style>h1 { font-size: 70px; }</style>'
        '<style>h1 { font-size: 20px; }</style>'
        '<link rel="stylesheet" href="packages/c/buz.css">'
        '</body></html>',
  });

  testLogOutput((options) => new HtmlFinalizer(options),
      'warns about multiple inlinings of the same css', {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="packages/a/foo.css">'
        '<link rel="stylesheet" href="packages/a/foo.css">'
        '</head><body></body></html>',
    'a|lib/foo.css': 'body {position: relative;}',
  }, {}, [
    'warning: ${CSS_FILE_INLINED_MULTIPLE_TIMES.create(
              {'url': 'lib/foo.css'}).snippet}'
        ' (web/test.html 0 76)',
  ]);

  testPhases('doesn\'t warn about multiple css inlinings if overriden', [
    [
      new HtmlFinalizer(
          new TransformOptions(inlineStylesheets: {'lib/foo.css': true}))
    ]
  ], {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" href="packages/a/foo.css">'
        '<link rel="stylesheet" href="packages/a/foo.css">'
        '</head><body></body></html>',
    'a|lib/foo.css': 'body {position: relative;}',
  }, {}, []);
}

void urlAttributeTests() {
  testLogOutput((options) => new HtmlFinalizer(options),
      'warnings are given about _* attributes', {
    'a|web/test.html': '<!DOCTYPE html><html><head></head><body>'
        '<img src="foo/{{bar}}">'
        '<a _href="foo/bar">test</a>'
        '</body></html>',
  }, {}, [
    'warning: When using bindings with the "src" attribute you may '
        'experience errors in certain browsers. Please use the "_src" '
        'attribute instead. (web/test.html 0 40)',
    'warning: The "_href" attribute is only supported when using '
        'bindings. Please change to the "href" attribute. '
        '(web/test.html 0 63)',
  ]);
}
