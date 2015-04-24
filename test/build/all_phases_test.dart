// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.all_phases_test;

import 'package:code_transformers/tests.dart' show testingDartSdkDirectory;
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/polymer_smoke_generator.dart'
    show MAIN_HEADER;
import 'package:polymer/transformer.dart';
import 'package:smoke/codegen/generator.dart' show DEFAULT_IMPORTS;
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = createDeployPhases(new TransformOptions(),
      sdkDir: testingDartSdkDirectory);

  testPhases('observable changes', phases, {
    'a|web/test.dart': _sampleInput('A', 'foo'),
    'a|web/test2.dart': _sampleOutput('B', 'bar'),
  }, {
    'a|web/test.dart': _sampleOutput('A', 'foo'),
    'a|web/test2.dart': _sampleOutput('B', 'bar'),
  });

  testPhases('single script', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="import" href="packages/polymer/polymer.html">'
        '<script type="application/dart" src="a.dart"></script>',
    'a|web/a.dart': _sampleInput('A', 'foo'),
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '$COMPATIBILITY_JS_TAGS'
        '</head><body><div hidden="">'
        '<script src="test.html.polymer.bootstrap.dart.js" async=""></script>'
        '</div>'
        '</body></html>',
    'a|web/test.html.polymer.bootstrap.dart': '''$MAIN_HEADER
          import 'test.web_components.bootstrap.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'package:polymer/polymer.dart' as smoke_0;
          import 'a.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_1.XA: smoke_0.PolymerElement,
                },
                declarations: {
                  smoke_1.XA: {},
                  smoke_0.PolymerElement: {},
                }));
            configureForDeployment();
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    'a|web/test.web_components.bootstrap.dart': '''
          import 'package:initialize/src/static_loader.dart';
          import 'package:initialize/initialize.dart';
          import 'test.bootstrap.dart' as i0;
          import 'a.dart' as i1;
          import 'package:polymer/polymer.dart' as i2;

          main() {
            initializers.addAll([new InitEntry(const i2.CustomTag('x-A'), i1.XA),]);

            i0.main();
          }
          '''.replaceAll('          ', ''),
    'a|web/test.bootstrap.dart': '''
          library a.web.test_bootstrap_dart;

          import 'a.dart' as i0;

          void main() { i0.main(); }
          '''.replaceAll('          ', ''),
  }, []);

  testPhases('single script in subfolder', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="import" href="packages/polymer/polymer.html">'
        '<script type="application/dart" src="foo/a.dart"></script>',
    'a|web/foo/a.dart': _sampleInput('A', 'foo'),
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '$COMPATIBILITY_JS_TAGS'
        '</head><body><div hidden="">'
        '<script src="test.html.polymer.bootstrap.dart.js" async=""></script>'
        '</div>'
        '</body></html>',
    'a|web/test.html.polymer.bootstrap.dart': '''$MAIN_HEADER
        import 'test.web_components.bootstrap.dart' as i0;
        ${DEFAULT_IMPORTS.join('\n')}
        import 'package:polymer/polymer.dart' as smoke_0;
        import 'foo/a.dart' as smoke_1;

        void main() {
          useGeneratedCode(new StaticConfiguration(
              checkedMode: false,
              parents: {
                smoke_1.XA: smoke_0.PolymerElement,
              },
              declarations: {
                smoke_1.XA: {},
                smoke_0.PolymerElement: {},
              }));
          configureForDeployment();
          i0.main();
        }
        '''.replaceAll('\n        ', '\n'),
    'a|web/test.web_components.bootstrap.dart': '''
        import 'package:initialize/src/static_loader.dart';
        import 'package:initialize/initialize.dart';
        import 'test.bootstrap.dart' as i0;
        import 'foo/a.dart' as i1;
        import 'package:polymer/polymer.dart' as i2;

        main() {
          initializers.addAll([new InitEntry(const i2.CustomTag('x-A'), i1.XA),]);

          i0.main();
        }
        '''.replaceAll('        ', ''),
    'a|web/test.bootstrap.dart': '''
        library a.web.test_bootstrap_dart;

        import 'foo/a.dart' as i0;

        void main() { i0.main(); }
        '''.replaceAll('        ', ''),
  }, []);

  testPhases('single inline script', phases, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="import" href="packages/polymer/polymer.html">'
        '<script type="application/dart">'
        '${_sampleInput("B", "bar")}</script>',
  }, {
    'a|web/test.html': '<!DOCTYPE html><html><head>'
        '$COMPATIBILITY_JS_TAGS'
        '</head><body><div hidden="">'
        '<script src="test.html.polymer.bootstrap.dart.js" async=""></script>'
        '</div>'
        '</body></html>',
    'a|web/test.html.polymer.bootstrap.dart': '''$MAIN_HEADER
          import 'test.web_components.bootstrap.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'package:polymer/polymer.dart' as smoke_0;
          import 'test.html.0.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_1.XB: smoke_0.PolymerElement,
                },
                declarations: {
                  smoke_0.PolymerElement: {},
                  smoke_1.XB: {},
                }));
            configureForDeployment();
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    'a|web/test.web_components.bootstrap.dart': '''
          import 'package:initialize/src/static_loader.dart';
          import 'package:initialize/initialize.dart';
          import 'test.bootstrap.dart' as i0;
          import 'test.html.0.dart' as i1;
          import 'package:polymer/polymer.dart' as i2;

          main() {
            initializers.addAll([new InitEntry(const i2.CustomTag('x-B'), i1.XB),]);

            i0.main();
          }
          '''.replaceAll('          ', ''),
    'a|web/test.bootstrap.dart': '''
          library a.web.test_bootstrap_dart;

          import 'test.html.0.dart' as i0;

          void main() { i0.main(); }
          '''.replaceAll('          ', ''),
    'a|web/test.html.0.dart': _sampleOutput("B", "bar"),
  }, []);

  testPhases('with imports', phases, {
    'a|web/index.html': '<!DOCTYPE html><html><head>'
        '<link rel="import" href="packages/polymer/polymer.html">'
        '<link rel="import" href="packages/a/test2.html">'
        '</head><body>'
        '<script type="application/dart" src="b.dart"></script>',
    'a|web/b.dart': _sampleInput('B', 'bar'),
    'a|lib/test2.html': '<!DOCTYPE html><html><head>'
        '<link rel="import" href="../../packages/polymer/polymer.html">'
        '</head><body>'
        '<polymer-element name="x-a">1'
        '<script type="application/dart">'
        '${_sampleInput("A", "foo")}</script>'
        '</polymer-element></html>',
  }, {
    'a|web/index.html': '<!DOCTYPE html><html><head>'
        '$COMPATIBILITY_JS_TAGS'
        '</head><body>'
        '<div hidden="">'
        '<polymer-element name="x-a">1</polymer-element>'
        '</div>'
        '<script src="index.html.polymer.bootstrap.dart.js" async=""></script>'
        '</body></html>',
    'a|web/index.html.polymer.bootstrap.dart': '''$MAIN_HEADER
          import 'index.web_components.bootstrap.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'package:polymer/polymer.dart' as smoke_0;
          import 'index.html.0.dart' as smoke_1;
          import 'b.dart' as smoke_2;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_2.XB: smoke_0.PolymerElement,
                  smoke_1.XA: smoke_0.PolymerElement,
                },
                declarations: {
                  smoke_2.XB: {},
                  smoke_1.XA: {},
                  smoke_0.PolymerElement: {},
                }));
            configureForDeployment();
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    'a|web/index.web_components.bootstrap.dart': '''
          import 'package:initialize/src/static_loader.dart';
          import 'package:initialize/initialize.dart';
          import 'index.bootstrap.dart' as i0;
          import 'index.html.0.dart' as i1;
          import 'package:polymer/polymer.dart' as i2;
          import 'b.dart' as i3;

          main() {
            initializers.addAll([
              new InitEntry(const i2.CustomTag('x-A'), i1.XA),
              new InitEntry(const i2.CustomTag('x-B'), i3.XB),
            ]);

            i0.main();
          }
          '''.replaceAll('          ', ''),
    'a|web/index.bootstrap.dart': '''
          library a.web.index_bootstrap_dart;

          import 'index.html.0.dart' as i0;
          import 'b.dart' as i1;

          void main() { i1.main(); }
          '''.replaceAll('          ', ''),
    'a|web/index.html.0.dart': _sampleOutput("A", "foo"),
  }, []);

  testPhases('test compatibility', phases, {
    'a|test/test.html': '<!DOCTYPE html><html><head>'
        '<link rel="x-dart-test" href="a.dart">'
        '<script src="packages/test/dart.js"></script>',
    'a|test/a.dart': _sampleInput('A', 'foo'),
  }, {
    'a|test/test.html': '<!DOCTYPE html><html><head>'
        '$COMPATIBILITY_JS_TAGS'
        '<link rel="x-dart-test" href="test.html.polymer.bootstrap.dart">'
        '<script src="packages/test/dart.js"></script>'
        '</head><body></body></html>',
  }, []);
}

String _sampleInput(String className, String fieldName) => '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';
import 'package:polymer/polymer.dart';

class $className extends Observable {
  @observable int $fieldName;
  $className(this.$fieldName);
}

@CustomTag('x-$className')
class X${className} extends PolymerElement {
  X${className}.created() : super.created();
}
@initMethod m_$fieldName() {}
main() {}
''';

String _sampleOutput(String className, String fieldName) {
  var fieldReplacement = '@reflectable @observable '
      'int get $fieldName => __\$$fieldName; '
      'int __\$$fieldName; '
      '@reflectable set $fieldName(int value) { '
      '__\$$fieldName = notifyPropertyChange(#$fieldName, '
      '__\$$fieldName, value); }';
  return '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';
import 'package:polymer/polymer.dart';

class $className extends ChangeNotifier {
  $fieldReplacement
  $className($fieldName) : __\$$fieldName = $fieldName;
}

@CustomTag('x-$className')
class X${className} extends PolymerElement {
  X${className}.created() : super.created();
}
@initMethod m_$fieldName() {}
main() {}
''';
}
