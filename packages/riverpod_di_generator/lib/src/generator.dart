import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';

class const RiverpodDiGenerator() extends GeneratorForAnnotation<RiverDi> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) => '// TEST';
}
