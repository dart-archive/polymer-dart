// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer.test.sort_registration_test;

// D will be registered after B below.
@CustomTag('x-d')
class D extends B {
  D.created() : super.created();
}

@CustomTag('x-b')
class B extends A {
  B.created() : super.created();
}

// C is declared in another file, but it will be registered after B and before E
@CustomTag('x-e')
class E extends C {
  E.created() : super.created();
}
