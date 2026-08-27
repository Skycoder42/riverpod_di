import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

/// The primary builder of the package
Builder riverpodDiBuilder(BuilderOptions options) =>
    PartBuilder([RiverpodDiGenerator(options)], '.di.g.dart', options: options);
