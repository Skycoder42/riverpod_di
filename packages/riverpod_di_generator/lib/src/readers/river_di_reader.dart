import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/code_gen.dart';
import 'package:source_gen/source_gen.dart';

class RiverDiReader(final ConstantReader _reader) {
  Expression get annotation => _reader.read('annotation').toExpression();
}
