Polymer.dart
============

Polymer.dart is a set of comprehensive UI and utility components
for building web applications.
With Polymer.dart's custom elements, templating, data binding,
and other features,
you can quickly build structured, encapsulated, client-side web apps.

Polymer.dart is a Dart port of
[Polymer][polymer] created and maintained by the Dart team.
The Dart team is collaborating with the Polymer team to ensure that polymer.dart
elements and polyfills are fully compatible with Polymer.

Polymer.dart replaces Web UI, which has been deprecated.


Learn More
----------

* The [Polymer.dart][wiki] homepage
contains a list of features, project status,
installation instructions, tips for upgrading from Web UI,
and links to other documentation.

* See our [TodoMVC][todo_mvc] example on github.

* For more information about Dart, see <http://www.dartlang.org/>.

Try It Now
-----------
Add the polymer.dart package to your pubspec.yaml file:

```yaml
dependencies:
  polymer: ^1.0.0
```

Instead of using `any`, we recommend using version ranges to avoid getting your
project broken on each release. Using a version range lets you upgrade your
package at your own pace. You can find the latest version number at
<https://pub.dartlang.org/packages/polymer>.

**Note**: While in `release_candidate` stage, we recommend that you pin to a
specific version:

```yaml
dependencies:
  polymer: 1.0.0-rc1
```

Building and Deploying
----------------------

To build a deployable version of your app, add the web_components and polymer
transformers to your pubspec.yaml file:

```yaml
transformers:
- web_components:
    entry_points:
    - web/index.html
- reflectable:
    entry_points:
    - web/index.dart
```

Then, run `pub build`.

Testing
-------

Polymer elements can be tested using either the original `unittest` or new
`test` packages. Just make sure to wait for `initPolymer()` to complete before
running your tests:

```dart
@TestOn('browser')
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

void main() async {
  await initPolymer();
  // Define your tests/groups here.
}
```

You will also need to define a custom html file for your test (see the README
for the [test][test] package for more information on this).

**Note**: If you are using the new `test` package, it is important that you add
the `test` transformer after the polymer transformer, so it should look roughly
like this:

```yaml
transformer:
- web_components:
    entry_points:
    - test/my_test.html
- reflectable:
    entry_ponits:
    - test/my_test.dart
- test/pub_serve:
    $include: test/**_test{.*,}.dart
```

Contacting Us
-------------

Please file issues in our [Issue Tracker][issues] or contact us on the
[Dart Web UI mailing list][mailinglist].

[issues]: https://github.com/dart-lang/polymer-dart/issues/new
[mailinglist]: https://groups.google.com/a/dartlang.org/forum/?fromgroups#!forum/web
[wiki]: https://github.com/dart-lang/polymer-dart/wiki
[polymer]: http://www.polymer-project.org/
[todo_mvc]: https://github.com/dart-lang/sample-todomvc-polymer/
[test]: https://github.com/dart-lang/test
