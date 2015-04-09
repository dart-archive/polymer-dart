// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of polymer;

/// Automatically registers a polymer element.
class CustomTag implements Initializer<Type> {
  final String tagName;
  const CustomTag(this.tagName);

  @override
  initialize(Type t) => Polymer.register(tagName, t);
}

/// Calls a zero argument [Function] after [Polymer.onReady] completes.
typedef dynamic _ZeroArg();
class _WhenPolymerReady implements Initializer<_ZeroArg> {
  const _WhenPolymerReady();

  @override
  void initialize(_ZeroArg f) {
    Polymer.onReady.then((_) => f());
  }
}

const whenPolymerReady = const _WhenPolymerReady();

