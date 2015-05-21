library index;

import 'dart:html';
import 'dart:js';
import 'package:initialize/initialize.dart';
import 'package:polymer/polymer_micro.dart';
import 'package:web_components/web_components.dart';
export 'package:web_components/init.dart';

@initMethod
ready() {
  var e = querySelector('my-element') as MyElement;
  print(e.outerHtml);
  print(e.baz);
}

@CustomElement('my-element')
class MyElement extends PolymerMicroElement {
  String baz;

  MyElement.created() : super.created() {
    // Extra proxies for this element!
    context['Object'].callMethod('defineProperty', [
      jsThis,
      'baz',
      new JsObject.jsify({
        'get': () => baz,
        'set': (newBaz) { baz = newBaz; },
      }),
    ]);

    marshalAttributes();
    installHostAttributes({
      'foo': 'bar',
    });
  }
}
