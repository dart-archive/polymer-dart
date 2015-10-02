@TestOn('browser')
library polymer.test.src.template.dom_if_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

main() async {
  await initPolymer();

  UserElement element;

  group('dom-if', () {
    setUp(() {
      element = new UserElement();
    });

    test('basic', () {
      element.set('user', new User('A', true));
      element.adminIf.render();
      expect(
          Polymer.dom(element.root).querySelector('.admin-only').style.display,
          isNot('none'));
      element.set('user.isAdmin', false);
      element.adminIf.render();
      expect(
          Polymer.dom(element.root).querySelector('.admin-only').style.display,
          'none');
      element.set('user.isAdmin', true);
      element.adminIf.render();
      expect(
          Polymer.dom(element.root).querySelector('.admin-only').style.display,
          isNot('none'));
    });
  });
}

@PolymerRegister('user-element')
class UserElement extends PolymerElement {
  UserElement.created() : super.created();
  factory UserElement() => document.createElement('user-element');

  DomIf get adminIf => $['adminIf'];

  @property
  User user;
}

class User extends JsProxy {
  @reflectable
  String name;

  @reflectable
  bool isAdmin;

  User(this.name, [this.isAdmin = false]);
}
