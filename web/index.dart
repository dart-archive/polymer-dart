library index;

import 'dart:html';
import 'package:initialize/initialize.dart';
import 'package:polymer/polymer_micro.dart';
import 'package:web_components/web_components.dart';
export 'package:web_components/init.dart';

@initMethod
ready() {
  document.body.append(document.createElement('my-element'));
}

@CustomElement('my-element')
class MyElement extends PolymerMicroElement {
  MyElement.created() : super.created() {
    installHostAttributes({
      'foo': 'bar',
    });
  }
}
