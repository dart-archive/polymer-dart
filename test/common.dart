library polymer_dart.test.common;

import 'dart:async';

Future wait(int milliseconds) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}
