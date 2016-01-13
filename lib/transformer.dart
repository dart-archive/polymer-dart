// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.transformer;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:reflectable/transformer.dart';
import 'package:web_components/transformer.dart';

class PolymerTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  PolymerTransformerGroup(BarbackSettings settings)
      : phases = createDeployPhases(settings);

  PolymerTransformerGroup.asPlugin(BarbackSettings settings) : this(settings);
}

/// Create deploy phases for Polymer.
List<List<Transformer>> createDeployPhases(BarbackSettings settings) {
  /// Validate the settings
  const validOptions = const ['entry_points'];
  for (var option in settings.configuration.keys) {
    if (validOptions.contains(option)) continue;
    throw 'Invalid option ``$option` supplied to polymer transformer. '
        'The recognized options are ${validOptions.join(' ')}.';
  }

  var options = new TransformOptions(
      _readFileList(settings.configuration['entry_points'])
          .map(_systemToAssetPath)
          .toList(),
      settings.mode == BarbackMode.RELEASE);

  return [
    /// Must happen first, temporarily rewrites <link rel="x-dart-test"> tags to
    /// <script type="application/dart" _was_test></script> tags.
    [new RewriteXDartTestToScript(options.entryPoints)],
    [new ScriptCompactorTransformer(options.entryPoints)],
    [new WebComponentsTransformer(options)],
    [
      new ImportInlinerTransformer(
          options.entryPoints, ['[[', '{{'])
    ],
    [
      new ReflectableTransformer.asPlugin(new BarbackSettings(
          _reflectableConfiguration(settings.configuration), settings.mode))
    ],

    /// Must happen last, rewrites
    /// <script type="application/dart" _was_test></script> tags back to
    /// <link rel="x-dart-test"> tags.
    [new RewriteScriptToXDartTest(options.entryPoints)],
  ];
}

/// Convert system paths to asset paths (asset paths are posix style).
String _systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}

List<String> _readFileList(value) {
  var files = [];
  bool error;
  if (value is List) {
    files = value;
    error = value.any((e) => e is! String);
  } else if (value is String) {
    files = [value];
    error = false;
  } else {
    error = true;
  }
  if (error) {
    print('Invalid value for "entry_points" in the polymer transformer.');
  }
  return files;
}

Map _reflectableConfiguration(Map originalConfiguration) {
  return {
    'formatted': originalConfiguration['formatted'],
    'supressWarnings': originalConfiguration['supressWarnings'],
    'entry_points': _readFileList(originalConfiguration['entry_points'])
        .map((e) => e.replaceFirst('.html', '.bootstrap.initialize.dart'))
        .toList(),
  };
}
