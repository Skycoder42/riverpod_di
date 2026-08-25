import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:riverpod_analyzer_utils/riverpod_analyzer_utils.dart';
import 'package:source_gen/source_gen.dart';

import 'readers/river_di_reader.dart';
import 'readers/riverpod_reader.dart';

class ResolvedProvider({
  required final Reference provider,
  final bool isNotifier = false,
  final bool isAsync = false,
}) {
  this {
    if (isNotifier && isAsync) {
      throw ArgumentError('Cannot set both isNotifier and isAsync true');
    }
  }

  ResolvedProvider adjust({bool? isNotifier, bool? isAsync}) => .new(
    provider: provider,
    isNotifier: isNotifier ?? this.isNotifier,
    isAsync: isAsync ?? this.isAsync,
  );

  Expression toExpression() {
    if (isNotifier) {
      return provider.property('notifier');
    } else if (isAsync) {
      return provider.property('future');
    } else {
      return provider;
    }
  }
}

class ProviderResolver(final BuilderOptions options) {
  late final riverpodOptions = BuildYamlOptions.fromMap(options.config);

  Future<ResolvedProvider> resolveProviderFor(
    BuildStep buildStep,
    Element target,
    Element element,
  ) async {
    // case 1: annotated with RiverDi => automatic name derivation works fine
    final riverDi = element.riverDi;
    if (riverDi != null) {
      return .new(
        provider: refer(_providerName(element, riverDi.annotation)),
        isAsync: riverDi.async,
      );
    }

    // case 2: annotated with Riverpod => try to resolve via riverpod
    final riverpod = element.riverpod;
    if (riverpod.exists) {
      final providerRef =
          await _resolveRiverpod(buildStep, target, element, riverpod) ??
          refer(_providerName(element, riverpod));
      return .new(provider: providerRef, isNotifier: true);
    }

    // case 3: unknown provider => uses empty fallbacks as best guess
    return .new(provider: refer(_providerName(element, riverpod)));
  }

  /// Simplified version of [GeneratorProviderDeclarationElement.providerName]
  String _providerName(Element element, RiverpodReader riverpod) {
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
        'Your providerNameStripPattern definition is not a valid regular '
            r'expression: $options.providerNameStripPattern',
      );
    }

    final caseCorrectedBaseName = prefix.isEmpty
        ? baseName.lowerFirst
        : baseName.titled;
    return '$prefix$caseCorrectedBaseName$suffix';
  }

  Future<Reference?> _resolveRiverpod(
    BuildStep buildStep,
    Element target,
    Element element,
    RiverpodReader riverpod,
  ) async {
    final astNode = await buildStep.resolver.astNodeFor(element.firstFragment);
    if (astNode is! Declaration) {
      return null;
    }

    final provider = astNode.provider;
    if (provider == null) {
      return null;
    }

    if (provider.providerElement.isFamily) {
      throw InvalidGenerationSource(
        'Cannot automatically inject family providers!',
        element: target,
      );
    }

    return refer(provider.providerElement.providerName(riverpodOptions));
  }
}
