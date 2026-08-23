import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:riverpod_analyzer_utils/riverpod_analyzer_utils.dart';
import 'package:source_gen/source_gen.dart';

import 'readers/river_di_reader.dart';
import 'readers/riverpod_reader.dart';

class ProviderResolver(final BuilderOptions options) {
  late final riverpodOptions = BuildYamlOptions.fromMap(options.config);

  Future<Reference> resolveProviderFor(
    BuildStep buildStep,
    ClassElement element,
  ) async {
    // case 1: annotated with RiverDi
    final riverDi = element.riverDi;
    if (riverDi != null) {
      return refer(_providerName(element, riverDi.annotation));
    }

    // case 2: annotated with Riverpod
    final riverpod = element.riverpod;
    if (riverpod != null) {
      final astNode = await buildStep.resolver.astNodeFor(
        element.firstFragment,
      );
      if (astNode is ClassDeclaration) {
        final provider = astNode.provider;
        print('IT WORKS: $provider');

        if (provider != null) {
          if (provider.providerElement.isFamily) {
            throw InvalidGenerationSource(
              'Cannot automatically inject family providers!',
              element: element, // TODO wrong element
            );
          }

          return refer(provider.providerElement.providerName(riverpodOptions));
        }
      }

      return refer(_providerName(element, riverpod));
    }

    // final providers = Stream.fromIterable(element.fragments)
    //     .asyncMap(buildStep.resolver.astNodeFor)
    //     .map((n) => n?.root as CompilationUnit?)
    //     .expand((u) => u?.declarations ?? const <CompilationUnitMember>[])
    //     .map((m) => m.provider);

    return refer('TEST');
  }

  /// Simplified version of [GeneratorProviderDeclarationElement.providerName]
  String _providerName(ClassElement element, RiverpodReader riverpod) {
    if (riverpod.name case final name?) return name;

    final prefix = riverpodOptions.providerNamePrefix;
    final suffix = riverpodOptions.providerNameSuffix;

    var baseName = element.name!;

    try {
      final regex = RegExp(riverpodOptions.providerNameStripPattern);
      baseName = baseName.replaceAll(regex, '');
    } on FormatException {
      throw ArgumentError.value(
        riverpodOptions.providerNameStripPattern,
        'providerNameStripPattern',
        r'Your providerNameStripPattern definition is not a valid regular expression: $options.providerNameStripPattern',
      );
    }

    return '$prefix${prefix.isEmpty ? baseName.lowerFirst : baseName.titled}$suffix';
  }
}
