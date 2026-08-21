import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder riverpodDiBuilder(BuilderOptions options) =>
    PartBuilder(const [RiverpodDiGenerator()], '.di.g.dart', options: options);
