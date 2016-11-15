#### 1.0.0-rc.19
  * Update analyzer, html, and reflectable versions.

#### 1.0.0-rc.18
  * Update tests because of `notifyPath` signature change

#### 1.0.0-rc.17
  * Update reflectable version to allow latest.
  * Fixed some analyzer hints.

#### 1.0.0-rc.16
  * Added new properties on `DomRepeat` :  `initialCount`, `renderedItemCount`
    and `targetFramerate`
  * Temporarily fixed reflectable version to `<0.5.3` due to
    [#690](https://github.com/dart-lang/polymer-dart/issues/690).

#### 1.0.0-rc.15
  * Fix a bug where calling `set` on a property from a behavior wouldn't update
    the property on the Dart element.

#### 1.0.0-rc.14
  * Added support for adding `@reflectable` to arbitrary static fields on
    both element classes and behavior mixins.
  * **Breaking Change**: Extending polymer element classes will no longer work.
    Specifically, `@property`, `@reflectable`, `@observe`, `@listen`, etc from
    your super class will no longer be picked up. These must all be moved into a
    behavior class which both elements mix in.

#### 1.0.0-rc.13
  * Transformer will now throw if given unrecognized options.

#### 1.0.0-rc.12
  * Update to work with polymer_interop v1.0.0-rc.8. The main difference relates
    to events. On the JS side of things, regular `Event` objects are sometimes
    used to mimic `CustomEvent` objects, and a `detail` field is just added.
    This means that Polymer Dart now treats any `Event` with a `detail` field as
    a `CustomEvent`, so they are wrapped with the `CustomEventWrapper` class.
    You can always get at the original event by using the `original` property.

#### 1.0.0-rc.11
  * Added a polymer transformer which wraps up both the web_components and
    reflectable transformers into one more consumable package. Use it just like
    the web_components transformer:

        transformers:
        - polymer:
            entry_points:
              - web/index.html

#### 1.0.0-rc.10
  * Update to reflectable `^0.5.0`  and analyzer `^0.27.0` versions.
  * Added back the `new_element` generator script.

#### 1.0.0-rc.9
  * `DomRepeatModel.item` is now deprecated, although it will properly use the
    `as` attribute for now. The `[]` operator has been added in its place.

#### 1.0.0-rc.8
  * Update to work with reflectable ^0.4.0.

#### 1.0.0-rc.7
  * Add version constraint on reflectable <0.3.4 until issue #651 is resolved.

#### 1.0.0-rc.6
  * Add a test/example for `Templatizer` behavior.
  * Fix a few minor strong mode type errors.

#### 1.0.0-rc.5
  * Update to work with `polymer_interop` version `1.0.0-rc.4`.

#### 1.0.0-rc.4
  * Throw on `registered` and `beforeRegister` instance methods if they
    are annotated with `@reflectable`.
  * Added support for static `registered` and `beforeRegister` methods, which
    will be invoked with the JS prototype for the element at registration time.
    These are supported for both behaviors and elements.
  * Fixed the `items` setter for the `DomRepeat` wrapper.
  * Temporarily added an analyzer constraint of `<0.26.1+15` to work around
    [#24735](https://github.com/dart-lang/sdk/issues/24735).

#### 1.0.0-rc.3
  * Annotations are no longer needed on both the getter and setter for fields,
    [#621](https://github.com/dart-lang/polymer-dart/issues/621).

#### 1.0.0-rc.2
  * The `@eventHandler` annotation has been replaced with the more general
    `@reflectable` annotation.
  * All fields/methods on `JsProxy` objects which you want to expose to JS need
    to be annotated with `@reflectable`. This results in dramatic code size
    improvement at relatively minimal cost to the user.

#### 1.0.0-rc.1
  * Port of polymer js 1.1.
  * This is a ground up rewrite, and has multiple breaking changes. See the
    [wiki](https://github.com/dart-lang/polymer-dart/wiki) for more information.

#### 0.16.3+2
  * Fix invalid warning about missing polymer.html import from the linter.
  * Update logging package to `<0.12.0`.

#### 0.16.3+1
  * Update observe to 0.13.1.

#### 0.16.3
  * Update analyzer to <0.26.0.

#### 0.16.2
  * Add support for the new `link[rel="x-dart-test"]` tags from the `test`
    package to the transformer.
  * The `Future` returned from the default `main` method in
    `package:polymer/init.dart` now guarantees that it will not complete until
    all `@initMethod` and `@whenPolymerReady` functions have been executed. This
    is to support writing tests inside these methods using the new `test`
    package.
  * Fix the bootstrap file to return the original result of main.

#### 0.16.1+4
  * Use `polymer_interop` for everything polymer js related. Projects which only
  provide/use wrappers around js elements should be able to switch to using that
  package instead of this one.

#### 0.16.1+3
  * Update polymer js version to 0.5.5.

#### 0.16.1+2
  * Update pubspec from `html5lib` to `html`.

#### 0.16.1+1
  * Switch `html5lib` package dependency to `html`.

#### 0.16.1
  * Added `@whenPolymerReady` annotation for functions. This will call the
    function once `Polymer.onReady` completes, reducing the boilerplate in entry
    points to the following:

        import 'package:polymer/polymer.dart';
        export 'package:polymer/init.dart';

        @whenPolymerReady
        void onReady() {
          /// Custom setup code here.
        }

#### 0.16.0+7
  * Switch to using `initWebComponents` internally which gives better guarantees
    around development time ordering of initializers. This should fix most
    issues related to element registration order.

#### 0.16.0+6
  * Update `args` constraint.
  * Pass `bindingStartDelimiters` to the `ImportInlinerTransformer` so it can
    handle bindings in urls appropriately,
    [#35](https://github.com/dart-lang/polymer-dart/issues/35).

#### 0.16.0+5
  * Update `web_components` constraint.

#### 0.16.0+4
  * Fix static configuration for exported libraries.

#### 0.16.0+3
  * Increase upper bound of `smoke` package to `<0.4.0`.

#### 0.16.0+2
  * Update the polyfill injector to work properly for entry points that live in
    sub-folders.

#### 0.16.0+1
  * Update analyzer and code_transformers versions and use new mock sdk from
    code_transformers.

#### 0.16.0
  * `initPolymer` now returns a `Future<Zone>` instead of a `Zone`. This will
    likely affect most polymer applications.

    Given a current program:

        main() => initPolymer().run(realMain);
        realMain() => ...

    This should be translated to:

        main() => initPolymer().then((zone) => zone.run(realMain));
        realMain() => ...

    Or alternatively, you can use an @initMethod:

        main() => initPolymer();    

        @initMethod
        realMain() => ...

  * Dropped support for the experimental bootstrap.
  * The `polymer` transformer is now integrated with the `initialize`
    transformer. This means you can now use `@HtmlImport` on library directives.
    This allows producers of elements to declare their own html dependencies so
    consumers don't have to know about your html imports at all. See
    [web_components 0.10.2](https://github.com/dart-lang/web-components/blob/master/CHANGELOG.md#0102)
    for more information on @HtmlImport.
  * The `startPolymer` method no longer takes a `deployMode` argument. This is
    meant as an internal-only method and should not affect apps. It also now
    returns a `Future`.
  * The transformer has been heavily refactored and may behave slightly
    differently. Please file any bugs related to this at
    https://github.com/dart-lang/polymer-dart/issues/new.

#### 0.15.5+4
  * Fix for [#23](https://github.com/dart-lang/polymer-dart/issues/23) (0.15.5+3
    missed an invocation of the observe transformer).

#### 0.15.5+3
  * Pass more state to the observe transformer so it won't output log files in
    release mode.

#### 0.15.5+2
  * Update duplicate css file message.

#### 0.15.5+1
  * Changes order in which CustomTags are registered to guarantee that the order
    is deterministic and that within a library superclasses are registered
    before subclasses. This fixes
    [17](https://github.com/dart-lang/polymer-dart/issues/17).

#### 0.15.5
  * Update to polymer js version
    [0.5.2](https://github.com/Polymer/polymer/releases/tag/0.5.2). This fixes
    [11](https://github.com/dart-lang/polymer-dart/issues/11).

#### 0.15.4
  * Fix template if when using template attribute
    [209](https://github.com/Polymer/TemplateBinding/issues/209).
  * Renamed `injectBoundHTML` to `injectBoundHtml` and changed its signature to
    use named instead of positional optional arguments. Also added support for
    custom `NodeValidator` and/or `TreeSanitizer`. The old version still exists
    for now with an `@deprecated` annotation.

#### 0.15.3+1
  * Fix logic for detecting when the compiler is linting within an
    `auto-binding-dart` template element. This removes some false positive
    warnings.

#### 0.15.3
  * Narrow the constraint on observe to ensure that new features are reflected
    in polymer's version.

#### 0.15.2
  * Upgraded to polymer js version
    [0.5.1](https://github.com/Polymer/polymer/releases/tag/0.5.1).
    **Dart Note**: Since dirty checking is only a development feature for
    Polymer Dart, we did not include the functionality to stop dirty checks in
    inactive windows.
  * `polymer.js` is now the unminified version, and `polymer.min.js` is the
    minified version.
  * Fixed bug where polymer js was creating instances of extended elements in
    order to check if they had been registered. All dart custom elements now get
    registered with polymer js using the HTMLElement prototype.

#### 0.15.1+5
  * Increase code_transformers lower bound and use shared transformers from it.

#### 0.15.1+4
  * Fix double-registration bug when using exports
    [21439](http://dartbug.com/21439).

#### 0.15.1+3
  * Make sure that `dart_support.js` is always appended after `platform.js`,
    [21435](http://dartbug.com/21435).

#### 0.15.1+2
  * Handle and warn about cases where a script file is included twice from the
    same entrypoint [21332](http://dartbug.com/21332).

#### 0.15.1+1
  * Fix typo in error message polymer#42

#### 0.15.1
  * Upgraded to polymer [0.4.2][]
  * No need to include dart_support.js in your entrypoints anymore.

#### 0.15.0+1
  * Widen web_components version constraint.

#### 0.15.0
  * Upgraded to polymer 0.4.1
  * Added Polymer.forceReady method. This forces a ready state regardless of
    whether or not there are still polymer-element declarations waiting for
    their class definitions to be loaded.
  * Added Polymer.waitingFor method. This returns a list of all polymer-element
    declarations that are still waiting for their class definitions to be
    loaded.
  * Add runtime checking of the waitingFor queue and print to the console if a
    deadlock situation is suspected to help diagnose the white screen of death.
  * Added injectBoundHTML instance method. This can be used to dynamically
    inject html that is bound to your current element into a target element.

#### 0.14.3
  * Warn if the same css file is inlined more than once,
    [19996](http://dartbug.com/19996).
  * Don't start moving elements from head to body until we find the first
    import, [20826](http://dartbug.com/20826).
  * Add option to not inject platform.js in the build output
    [20865](http://dartbug.com/20865). To use, set `inject_platform_js` to
    false in the polymer transformer config section of your pubspec.yaml:

        transformers:
        - polymer:
            inject_platform_js: false
            ...

#### 0.14.2+1
  * Fix findController function for js or dart wrapped elements. This fixes
    event bindings when using paper-dialog and probably some other cases,
    [20931](http://dartbug.com/20931).

#### 0.14.2
  * Polymer will now create helpful index pages in all folders containing entry
    points and in their parent folders, in debug mode only
    [20963](http://dartbug.com/20963).

#### 0.14.1
  * The build.dart file no longer requires a list of entry points, and you can
    replace the entire file with `export 'package:polymer/default_build.dart';`
    [20396](http://dartbug.com/20396).
  * Inlined imports from the head of the document now get inserted inside a
    hidden div, similar to the js vulcanizer [20943](http://dartbug.com/20943).

#### 0.14.0+1
  * Small style improvements on error/warnings page.

#### 0.14.0
  * Upgraded to polymer 0.4.0 ([polymer-dev#d66a86e][d66a86e]).
  * The platform.js script is no longer required in Chrome or Dartium
    (version 36). You can now remove this from your projects for development,
    and it will be injected when running pub build or pub serve. If you would
    like the option to not inject platform.js at all in the built output (if you
    are deploying to chrome exclusively), please star this bug
    http://dartbug.com/20865.
  * Fixed invalid linter warning when using event handlers inside an
    `auto-binding-dart` template, [20913](http://dartbug.com/20913).

#### 0.13.1
  * Upgraded error messages to have a unique and stable identifier. This
    requires a version of `code_transformers` newer than `0.2.3`.
  * Upgraded minimum version constraint on `args` to `0.11.0`.

#### 0.13.0+3
  * Added a warning about flashes of unstyled content if we can detect a
    situation that would cause it [20751](http://dartbug.com/20751).

#### 0.13.0+2
  * Update internal transformers to delete .concat.js and .map files when in
    release mode, saving about 1MB of space in the built output.

#### 0.13.0+1
  * Bug fix for http://dartbug.com/18171. Elements that extend other elements
    but don't have a template will still inherit styles from those elements.
  * Bug fix for http://dartbug.com/20544. Better runtime logging when attributes
    are defined on an element but have no corresponding property on the class.

#### 0.13.0
  * Update to match polymer 0.3.5 ([polymer-dev#5d00e4b][5d00e4b]). There was a
    breaking change in the web_components package where selecting non-rendered
    elements doesn't work, but it shouldn't affect most people. See
    https://github.com/Polymer/ShadowDOM/issues/495.

#### 0.12.2+1
  * Small bug fix for `polymer:new_element`

#### 0.12.2
  * Fix for [20539](http://dartbug.com/20539). Log widget will now html escape
    messages.
  * Fix for [20538](http://dartbug.com/20538). Log widget will now surface lint
    logs from imported files.
  * Backward compatible change to prepare for upcoming change of the user agent
    in Dartium.
  * `pub run polymer:new_element` now supports specifying a base class.
    **Note**: only native DOM types and custom elements written in Dart can be
    extended. Elements adapted from Javascript (like core- and paper- elements)
    cannot be extended.
  * other bug fixes in `polymer:new_entry`.

#### 0.12.1
  * **New**: When running in pub-serve, any warnings and errors detected by the
    polymer transformers will be displayed in the lower-right corner of your
    entrypoint page. You can opt-out by adding this option to your pubspec:

        transformers:
        - polymer:
            ...
            inject_build_logs_in_output: false

  * **New**: there are now two template generators in the polymer package! On
    any project that depends on polymer, you can create template files for a new
    custom element by invoking:

        pub run polymer:new_element element-name [-o output_dir]

    And, if you invoke:

        pub run polymer:new_entry web/index.html

    we will create a new entry-point file and add it to your pubspec for you.

  * Added the ability to override the stylesheet inlining behavior. There is now
    an option exposed in the pubspec.yaml called `inline_stylesheets`. There are
    two possible values, a boolean or a map. If only a boolean is supplied then
    that will set the global default behavior. If a map is supplied, then the
    keys should be file paths, and the value is a boolean. You can use the
    special key 'default' to set the default value.

    For example, the following would change the default to not inline any
    styles, except for the foo.css file in your web folder and the bar.css file
    under the foo packages lib directory:

        transformers:
        - polymer:
            ...
            inline_stylesheets:
                default: false
                web/foo.css: true
                packages/foo/bar.css: true


  * Bug fix for http://dartbug.com/20286. Bindings in url attributes will no
    longer throw an error.


#### 0.12.0+7
  * Widen the constraint on `unittest`.

#### 0.12.0+6
  * Widen the constraint on analyzer.
  * Support for `_src` and similar attributes in polymer transformers.

#### 0.12.0+5
  * Raise the lower bound on the source_maps constraint to exclude incompatible
    versions.

#### 0.12.0+4
  * Widen the constraint on source_maps.

#### 0.12.0+3
  * Fix a final use of `getLocationMessage`.

#### 0.12.0+2
  * Widen the constraint on barback.

#### 0.12.0+1
  * Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan`
    class.

#### 0.12.0
 * Updated to match polymer 0.3.4 ([polymer-dev#6ad2d61][6ad2d61]), this
   includes the following changes:
     * added @ComputedProperty
     * @published can now be written using the readValue/writeValue helper
       methods to match the same timing semantics as Javscript properties.
     * underlying packages are also updated. Some noticeable changes are:
       * observe: path-observers syntax is slightly different
       * polymer_expressions: updating the value of an expression will issue a
         notification.
       * template_binding: better NodeBind interop support (for
         two-way bindings with JS polymer elements).
 * Several fixes for CSP, including a cherry-pick from polymer.js
   [commit#3b690ad][3b690ad].
 * Fix for [17596](https://code.google.com/p/dart/issues/detail?id=17596)
 * Fix for [19770](https://code.google.com/p/dart/issues/detail?id=19770)

#### 0.11.0+5
  * fixes web_components version in dependencies

#### 0.11.0+4
  * workaround for bug
    [19653](https://code.google.com/p/dart/issues/detail?id=19653)

#### 0.11.0+3
  * update readme

#### 0.11.0+2
  * bug fix: event listeners were not in the dirty-checking zone
  * bug fix: dispatch event in auto-binding

#### 0.11.0+1
  * Added a workaround for bug in HTML imports (issue
    [19650](https://code.google.com/p/dart/issues/detail?id=19650)).

#### 0.11.0
  * **breaking change**: platform.js and dart_support.js must be specified in
    your entry points at the beginning of `<head>`.
  * **breaking change**: polymer.html is not required in entrypoints, but it is
    required from files that use `<polymer-element>`.
  * **breaking change**: enteredView/leftView were renamed to attached/detached.
    The old lifecycle methods will not be invoked.
  * **breaking change**: Event bindings with `@` are no longer supported.
  * **breaking change**: `@published` by default is no longer reflected as an
    attribute by default. This might break if you try to use the attribute in
    places like CSS selectors. To make it reflected back to an attribute use
    `@PublishedProperty(reflect: true)`.

#### 0.10.1
  * Reduce the analyzer work by mocking a small subset of the core libraries.

#### 0.10.0+1
  * Better error message on failures in pub-serve/pub-build when pubspec.yaml
    is missing or has a wrong configuration for the polymer transformers.

#### 0.10.0
  * Interop with polymer-js elements now works.
  * Polymer polyfills are now consolidated in package:web_components, which is
    identical to platform.js from http://polymer-project.org.
  * The output of pub-build no longer uses mirrors. We replace all uses of
    mirrors with code generation.
  * **breaking change**: Declaring a polymer app requires an extra import to
    `<link rel="import" href="packages/polymer/polymer.html">`
  * **breaking change**: "noscript" polymer-elements are created by polymer.js,
    and therefore cannot be extended (subtyped) in Dart. They can still be used
    by Dart elements or applications, however.
  * New feature: `@ObserveProperty('foo bar.baz') myMethod() {...}` will cause
    myMethod to be called when "foo" or "bar.baz" changes.
  * Updated for 0.10.0-dev package:observe and package:template_binding changes.
  * **breaking change**: @initMethod and @CustomTag are only supported on
    public classes/methods.

#### 0.9.5
  * Improvements on how to handle cross-package HTML imports.

#### 0.9.4
  * Removes unused dependency on csslib.

#### 0.9.3+3
  * Removes workaround now that mirrors implement a missing feature. Requires
    SDK >= 1.1.0-dev.5.0.

#### 0.9.3+2
  * Fix rare canonicalization bug
    [15694](https://code.google.com/p/dart/issues/detail?id=15694)

#### 0.9.3+1
  * Fix type error in runner.dart
    [15649](https://code.google.com/p/dart/issues/detail?id=15649).

#### 0.9.3
  * pub-build now runs the linter automatically

#### 0.9.2+4
  * fix linter on SVG and MathML tags with XML namespaces

#### 0.9.2+3
  * fix [15574](https://code.google.com/p/dart/issues/detail?id=15574),
    event bindings in dart2js, by working around issue
    [15573](https://code.google.com/p/dart/issues/detail?id=15573)

#### 0.9.2+2
  * fix enteredView in dart2js, by using custom_element >= 0.9.1+1

[0.4.2]: https://github.com/Polymer/polymer-dev/commit/8c339cf8614eb65145ec1ccbdba7ecbadf65b343
[6ad2d61]:https://github.com/Polymer/polymer-dev/commit/6a3e1b0e2a0bbe546f6896b3f4f064950d7aee8f
[3b690ad]:https://github.com/Polymer/polymer-dev/commit/3b690ad0d995a7ea339ed601075de2f84d92bafd
