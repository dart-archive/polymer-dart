// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.lib.src.common.listen;

import 'event_handler.dart';

/// Annotation class for methods, calls the annotated method when the named
/// event is fired. Equivalent to the `listeners` object in polymer js, see
/// https://www.polymer-project.org/1.0/docs/devguide/events.html#event-listeners.
class Listen extends EventHandler {
  final String eventName;
  const Listen(this.eventName) : super();
}
