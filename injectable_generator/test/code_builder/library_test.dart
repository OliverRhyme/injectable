import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:injectable_generator/code_builder/library_builder.dart';
import 'package:injectable_generator/models/dependency_config.dart';
import 'package:test/test.dart';

void main() {
  group('Library test group', () {
    test("Simple init function", () {
      expect(generate([DependencyConfig.factory('Demo')]), '''
// ignore_for_file: type=lint
// coverage:ignore-file

// initializes the registration of main-scope dependencies inside of GetIt
GetIt init(
  GetIt getIt, {
  String environment,
  EnvironmentFilter environmentFilter,
}) {
  final gh = GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factory<Demo>(() => Demo());
  return getIt;
}
''');
    });

    test("Simple asExtension init", () {
      expect(generate([DependencyConfig.factory('Demo')], asExt: true), '''
// ignore_for_file: type=lint
// coverage:ignore-file

extension GetItInjectableX on GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  GetIt init({
    String environment,
    EnvironmentFilter environmentFilter,
  }) {
    final gh = GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<Demo>(() => Demo());
    return this;
  }
}
''');
    });

    test("Multiple registrations generates enablement call", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        allowMultipleRegistrations: true,
      );
      expect(result, contains('getIt.enableRegisteringMultipleInstancesOfOneType()'));
    });

    test("Multiple registrations with extension generates enablement call", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        asExt: true,
        allowMultipleRegistrations: true,
      );
      expect(result, contains('this.enableRegisteringMultipleInstancesOfOneType()'));
    });

    test("Multiple registrations is not generated for micro packages", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        microPackageName: 'TestPackage',
        allowMultipleRegistrations: true,
      );
      expect(result, isNot(contains('enableRegisteringMultipleInstancesOfOneType')));
    });

    test("Multiple registrations is not generated when disabled", () {
      final result = generate(
        [DependencyConfig.factory('Demo')],
        allowMultipleRegistrations: false,
      );
      expect(result, isNot(contains('enableRegisteringMultipleInstancesOfOneType')));
    });
  });
}

String generate(
  List<DependencyConfig> input, {
  bool asExt = false,
  String? microPackageName,
  bool allowMultipleRegistrations = false,
}) {
  final library = LibraryGenerator(
    dependencies: List.of(input),
    initializerName: 'init',
    asExtension: asExt,
    microPackageName: microPackageName,
    allowMultipleRegistrations: allowMultipleRegistrations,
  ).generate();
  final emitter = DartEmitter(
    allocator: Allocator.none,
    orderDirectives: true,
    useNullSafetySyntax: false,
  );
  return DartFormatter(
    languageVersion: DartFormatter.latestShortStyleLanguageVersion,
  ).format(library.accept(emitter).toString());
}
