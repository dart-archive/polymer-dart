@TestOn('browser')
library polymer.test.src.template.dom_bind_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:smoke/mirrors.dart' as smoke;
import 'package:test/test.dart';

main() async {
  smoke.useMirrors();
  await initPolymer();

  DomBind domBind;
  UserElement userElement;
  DivElement userNameElement;

  group('dom-bind', () {
    setUp(() {
      domBind = querySelector('template[is=dom-bind]');
      domBind.render();
      userElement = querySelector('user-element');
      userNameElement = querySelector('.name');
    });

    test('basic', () {
      expect(userElement.text, contains(userElement.user.name));
      expect(userNameElement.text, contains(userElement.user.name));

      var user = new User('John');
      userElement.set('user', user);
      domBind.render();
      expect(userElement.text, contains(user.name));
      expect(userNameElement.text, contains(user.name));
    });
  });
}

@PolymerRegister('user-element')
class UserElement extends PolymerElement {
  UserElement.created() : super.created();
  factory UserElement() => document.createElement('user-element');

  @Property(notify: true)
  User user = new User('Bob');
}

class User extends JsProxy {
  String name;
  User(this.name);
}
