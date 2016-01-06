library polymer.test.common;

import 'package:observe/src/dirty_check.dart';
import 'package:test/test.dart' as original_test
    show test, group, setUp, tearDown;

export 'package:test/test.dart' hide test, group, setUp, tearDown;

/// Custom implementations of the functions from `package:test`. These ensure
/// that the body of all test function are run in the dirty checking zone.
test(String description, body(), {String skip}) => original_test.test(
    description, () => dirtyCheckZone().bindCallback(body)(), skip: skip);

group(String description, body()) => original_test.group(
    description, () => dirtyCheckZone().bindCallback(body)());

setUp(body()) =>
    original_test.setUp(() => dirtyCheckZone().bindCallback(body)());

tearDown(body()) =>
    original_test.tearDown(() => dirtyCheckZone().bindCallback(body)());
