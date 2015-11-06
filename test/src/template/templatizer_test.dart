@TestOn('browser')
library polymer.test.src.template.templatizer_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';
import '../../common.dart';

main() async {
  await initPolymer();

  UserListElement element;

  group('templatizer', () {
    setUp(() {
      element = fixture('basic');
    });

    test('initial state', () {
      PolymerDom.flush();
      var users = Polymer.dom(element.root).querySelectorAll('.user');
      expect(users.length, 3);
      var expected = ['Jack', 'Jill', 'John'];
      for (int i = 0; i < users.length; i++) {
        expect(users[i].text, contains(expected[i]));
      }
    });

    test('add/remove users', () {
      element.add('users', new User('Sally'));
      PolymerDom.flush();
      var users = Polymer.dom(element.root).querySelectorAll('.user');
      expect(users.length, 4);
      var expected = ['Jack', 'Jill', 'John', 'Sally'];
      for (int i = 0; i < users.length; i++) {
        expect(users[i].text, contains(expected[i]));
      }

      element.removeRange('users', 1, 3);
      PolymerDom.flush();
      users = Polymer.dom(element.root).querySelectorAll('.user');
      expect(users.length, 2);
      expected = ['Jack', 'Sally'];
      for (int i = 0; i < users.length; i++) {
        expect(users[i].text, contains(expected[i]));
      }
    });

    test('modify user', () {
      // Modify the name of an existing user.
      element.set('users.1.name', 'Phillip');
      var users = Polymer.dom(element.root).querySelectorAll('.user');
      expect(users.length, 3);
      var expected = ['Jack', 'Phillip', 'John'];
      for (int i = 0; i < users.length; i++) {
        expect(users[i].text, contains(expected[i]));
      }

      // Swap an entire user.
      element.set('users.0', new User('Alexa'));
      expect(users.length, 3);
      expected = ['Alexa', 'Phillip', 'John'];
      for (int i = 0; i < users.length; i++) {
        expect(users[i].text, contains(expected[i]));
      }
    });

    test('modelForElement', () {
      var users = Polymer.dom(element.root).querySelectorAll('.user');
      for (int i = 0; i < element.users.length; i++) {
        expect(element.modelForElement(users[i]).jsElement,
            element._instances[i].jsElement);
      }
    });
  });
}

@PolymerRegister('user-list')
class UserListElement extends PolymerElement with Templatizer {
  UserListElement.created() : super.created();
  factory UserListElement() => document.createElement('user-element');

  @property
  List<User> users = [new User('Jack'), new User('Jill'), new User('John')];

  TemplateElement _template;
  List<TemplateInstance> _instances = [];
  Map<String, TemplateInstance> _instancesByKey = {};
  bool _ready = false;
  PolymerCollection _usersCollection;

  ready() {
    _usersCollection = new PolymerCollection(users);
    _template = queryEffectiveChildren('template');
    templatize(_template);
    _reset();
    _ready = true;
  }

  _reset() {
    _instances.clear();
    _instancesByKey.clear();
    var dom = new PolymerDom($['users']);
    for (var child in dom.children) {
      dom.removeChild(child);
    }

    for (var user in users) {
      var instance = stamp({'user': user});
      (Polymer.dom($['users']) as PolymerDom).append(instance.root);
      _instances.add(instance);
      _instancesByKey[_usersCollection.getKey(user)] = instance;
    }
  }

  @Observe('users.*')
  void usersChanged(changeRecord) {
    if (!_ready) return;

    String path = changeRecord['path'];
    if (path == 'users') {
      _usersCollection = new PolymerCollection(users);
      _reset();
    } else if (path == 'users.splices') {
      // Remove any instances from the map by their key
      for (var splice in changeRecord['value']['keySplices']) {
        for (String key in splice['removed']) {
          _instancesByKey.remove(key);
        }
      }

      // Remove everything else based on index.
      for (var splice in changeRecord['value']['indexSplices']) {
        var index = splice['index'];
        var usersDiv = Polymer.dom($['users']) as PolymerDom;
        var userDivs = usersDiv.children;

        // Remove any items
        var removed = splice['removed'];
        for (int r = 0; r < removed.length; r++) {
          var adjustedIndex = index + r;
          usersDiv.removeChild(userDivs[adjustedIndex]);
          _instances.removeAt(adjustedIndex);
          // _instancesByKey is updated in previous for loop
        }

        // Add any new items
        var addedCount = splice['addedCount'];
        for (int a = 0; a < addedCount; a++) {
          var adjustedIndex = index + a;
          var instance = stamp({'user': users[adjustedIndex]});
          if (userDivs.length > adjustedIndex) {
            usersDiv.insertBefore(instance.root, userDivs[adjustedIndex]);
          } else {
            usersDiv.append(instance.root);
          }
          _instances.insert(adjustedIndex, instance);
          var user = users[adjustedIndex];
          _instancesByKey[_usersCollection.getKey(user)] = user;
        }
      }
    } else if (path.startsWith('users.#')) {
      var parts = path.split('.');
      var instance = _instancesByKey[parts[1]];
      instance.notifyPath(
          (['user']..addAll(parts.getRange(2, parts.length))).join('.'),
          get(path),
          fromAbove: true);
    }
  }
}

class User extends JsProxy {
  @reflectable
  String name;

  User(this.name);
}
