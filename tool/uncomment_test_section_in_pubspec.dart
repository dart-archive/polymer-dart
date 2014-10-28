library polymer.tool.uncomment_test_section_in_pubspec;

import 'dart:io';

main(args) {
  var pubspec = new File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print("uncomment_test_section_in_pubspec error: pubspec doesn't exist.");
    exit(1);
  }
  var contents = pubspec.readAsStringSync();
  var begin = contents.indexOf("# ---prehook: begin uncomment---");
  var end = contents.indexOf("# ---prehook: end uncomment---", begin);
  var newContents = new StringBuffer()
      ..write(contents.substring(0, begin))
      ..write(contents.substring(begin, end).replaceAll('\n#', '\n'))
      ..write(contents.substring(end));
  pubspec.writeAsStringSync(newContents.toString());
  print('updated pubspec successfully');
}
