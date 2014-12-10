library polymer.tool.uncomment_test_section_in_pubspec;

import 'dart:io';

import 'package:path/path.dart';

main() {
  var scriptPath = Platform.script.path;
  if (context.style.name == 'windows') scriptPath = scriptPath.substring(1);
  var path = join(dirname(dirname(scriptPath)), 'pubspec.yaml');
  print('uncomment_test_section_in_pubspec: processing $path');
  var pubspec = new File(path);
  if (!pubspec.existsSync()) {
    print('uncomment_test_section_in_pubspec error: '
        'pubspec.yaml not found: $path.');
    exit(1);
  }
  var contents = pubspec.readAsStringSync();
  var begin = contents.indexOf("# ---prehook: begin uncomment---");
  if (begin == -1) {
    print('uncomment_test_section_in_pubspec error: '
        'start of commented section not found.');
    exit(1);
  }
  var end = contents.indexOf("# ---prehook: end uncomment---", begin);
  if (end == -1) {
    print('uncomment_test_section_in_pubspec error: '
        'end of commented section not found.');
    exit(1);
  }
  var newContents = new StringBuffer()
      ..write(contents.substring(0, begin))
      ..write(contents.substring(begin, end).replaceAll('\n# ', '\n'))
      ..write(contents.substring(end));
  pubspec.writeAsStringSync(newContents.toString());
  print('updated pubspec successfully');
}
