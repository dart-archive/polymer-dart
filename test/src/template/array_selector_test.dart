@TestOn('browser')
library polymer.test.src.template.array_selector_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

main() async {
  await initPolymer();

  EmployeeList element;

  group('array-selector', () {
    setUp(() {
      element = new EmployeeList();
      document.body.append(element);
    });

    test('basic', () {
      expect(element.selector.items.length, 2);
      expect(element.selectedEmployeeList.items.length, 0);
      expect(element.employeeList.items.length, 2);
      element.employeeList.render();

      Polymer.dom(element.root).querySelector('button').click();
      expect(element.selected, [element.employees[0]]);
      expect(element.selectedEmployeeList.items, element.selected);

      Polymer.dom(element.root).querySelectorAll('button')[1].click();
      expect(element.selected, element.employees);
      expect(element.selectedEmployeeList.items, element.selected);

      Polymer.dom(element.root).querySelector('button').click();
      expect(element.selectedEmployeeList.items, element.selected);
      expect(element.selected, [element.employees[1]]);

      Polymer.dom(element.root).querySelectorAll('button')[1].click();
      expect(element.selected, isEmpty);
      expect(element.selectedEmployeeList.items, element.selected);
    });
  });
}

@PolymerRegister('employee-list')
class EmployeeList extends PolymerElement {
  EmployeeList.created() : super.created();
  factory EmployeeList() => document.createElement('employee-list');

  @property
  List<Employee> employees;

  @property
  List<Employee> selected;

  ArraySelector get selector => $['selector'];
  DomRepeat get employeeList => $['employeeList'];
  DomRepeat get selectedEmployeeList => $['selectedEmployeeList'];

  ready() {
    set('employees',
        [new Employee('Bob', 'Smith'), new Employee('Sally', 'Johnson')]);
  }

  @eventHandler
  void toggleSelection(MouseEvent e, [_]) {
    var item = new DomRepeatModel.fromEvent(e).item;
    selector.select(item);
  }
}

class Employee extends JsProxy {
  String first;
  String last;
  Employee(this.first, this.last);
}
