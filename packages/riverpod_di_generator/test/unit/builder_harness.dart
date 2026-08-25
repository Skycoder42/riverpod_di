import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_di_generator/src/generator.dart';
import 'package:source_gen/source_gen.dart';

/// What a single generator run produced.
///
/// `output` is the generated code with the `part of` preamble stripped, or
/// `null` if the generator produced nothing. `errors` holds the messages of all
/// severe log records for that input, which is how `build_runner` surfaces a
/// thrown [InvalidGenerationSource].
typedef GenerationResult = ({String? output, List<String> errors});

const _package = 'riverpod_di_generator';

/// Runs [RiverpodDiGenerator] over in-memory sources.
///
/// The real `lib` sources of every package in this workspace are loaded into
/// the in-memory filesystem, so snippets can import `package:riverpod_di` and
/// resolve against the actual annotations.
final class BuilderHarness(final TestReaderWriter _readerWriter) {
  var _counter = 0;

  /// Creates a harness with all isolate sources loaded.
  ///
  /// This is slow, so share one harness per test file via `setUpAll`.
  static Future<BuilderHarness> create() async {
    final readerWriter = TestReaderWriter(
      rootPackage: _package,
      flattenOutput: true,
    );
    await readerWriter.testing.loadIsolateSources();
    return BuilderHarness(readerWriter);
  }

  /// Generates the provider part for [source].
  ///
  /// [source] is inserted into a library that already imports `riverpod_di` and
  /// declares the generated part, so it only needs the declarations under test.
  Future<GenerationResult> generate(String source) async {
    final name = 'input${_counter++}';
    final inputId = AssetId(_package, 'example/$name.dart');
    final outputId = AssetId(_package, 'example/$name.di.g.dart');
    final errors = <String>[];

    await testBuilder(
      PartBuilder([RiverpodDiGenerator(BuilderOptions.empty)], '.di.g.dart'),
      {
        '$inputId':
            "import 'package:riverpod_di/riverpod_di.dart';\n\n"
            "part '$name.di.g.dart';\n\n$source",
      },
      generateFor: {'$inputId'},
      readerWriter: _readerWriter,
      flattenOutput: true,
      // Inputs of earlier runs stay in the shared filesystem and are rebuilt
      // every time, so their failures show up again here. Keep only the ones
      // build_runner attributes to this input.
      onLog: (record) {
        if (record.level >= Level.SEVERE &&
            record.message.contains('on ${inputId.path}:')) {
          errors.add(record.message);
        }
      },
    );

    if (!_readerWriter.testing.assets.contains(outputId)) {
      return (output: null, errors: errors);
    }
    return (
      output: _stripPreamble(_readerWriter.testing.readString(outputId)),
      errors: errors,
    );
  }

  /// Drops the header, the `part of` directive and the generator banner.
  static String _stripPreamble(String output) {
    final lines = output.split('\n');
    final banner = lines.lastIndexWhere((line) => line.startsWith('// **'));
    return lines.skip(banner + 1).join('\n').trim();
  }
}
