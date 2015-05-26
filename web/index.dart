library index;

import 'dart:html';
import 'dart:js';
import 'package:initialize/initialize.dart';
import 'package:polymer/polymer_micro.dart';
//import 'package:web_components/web_components.dart';
export 'package:polymer/init.dart';

@initMethod
ready() {
  var e = querySelector('my-element') as MyElement;
  print(e.outerHtml);
  print(e.baz);
}

@PolymerElement('my-element', hostAttributes: const {'foo': 'bar'})
class MyElement extends PolymerMicroElement {
  String baz;

  MyElement.created() : super.created() {
    print(baz);
//    // Extra proxies for this element!
//    context['Object'].callMethod('defineProperty', [
//      jsThis,
//      'baz',
//      new JsObject.jsify({
//        'get': () => baz,
//        'set': (newBaz) { baz = newBaz; },
//      }),
//    ]);

//    hostAttributes['foo'] = 'bar';

//    marshalAttributes();
//    polymerCreated();
//    marshalAttributes();
//    installHostAttributes({
//      'foo': 'bar',
//    });
  }
}
