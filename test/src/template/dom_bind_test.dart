@TestOn('browser')
library polymer.test.src.template.dom_bind_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

main() async {
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

    test('set property on child', () {
      var bob = new User('Bob');
      userElement.set('user', bob);
      expect(userElement.text, contains('Bob'));
      expect(userNameElement.text, contains('Bob'));

      var john = new User('John');
      userElement.set('user', john);
      domBind.render();
      expect(userElement.text, contains('John'));
      expect(userNameElement.text, contains('John'));
    });

    test('set property on dom-bind instance', () {
      var bob = new User('Bob');
      domBind['user'] = bob;
      expect(userElement.text, contains('Bob'));
      expect(userNameElement.text, contains('Bob'));

      var john = new User('John');
      domBind['user'] = john;
      domBind.render();
      expect(userElement.text, contains('John'));
      expect(userNameElement.text, contains('John'));
    });
  });
}

@PolymerRegister('user-element')
class UserElement extends PolymerElement {
  UserElement.created() : super.created();
  factory UserElement() => document.createElement('user-element');

  @Property(notify: true)
  User user;
}

class User extends JsProxy {
  String name;
  User(this.name);
}
