import 'dart:io';

import 'package:test/test.dart';

const templateFile = 'test/fixtures/test_spec.yaml';
const activeFile = 'test/fixtures/_active_spec.yaml';

Future<ProcessResult> runHoriHori(Iterable<String> args) => Process.run(
      'dart',
      [
        'main.dart',
        '-f',
        activeFile,
        ...args,
      ],
    );

void main() {
  setUp(() => File.fromUri(Uri.parse(templateFile)).copy(activeFile));

  tearDownAll(() => File.fromUri(Uri.parse(activeFile)).delete());

  group('Hori-Hori CLI', () {
    group('hori-hori version', () {
      test('should print version information', () async {
        final result = await runHoriHori(['version']);

        expect(result.exitCode, 0);
        expect(result.stdout, contains('Hori-Hori version 1.0.0'));
      });
    });

    group('hori-hori current', () {
      test('should print current package version', () async {
        final result = await runHoriHori(['current']);

        expect(result.exitCode, 0);
        expect(result.stdout, '1.2.3+4\n');
      });
    });

    group('hori-hori bump', () {
      <String, String>{
        'major': '2.0.0\n',
        'minor': '1.3.0\n',
        'patch': '1.2.4\n',
        'build': '1.2.3+5\n',
      }.forEach((key, value) => test('$key bumps $key version', () async {
            final bumpResult = await runHoriHori(['bump', key]);
            expect(bumpResult.exitCode, 0);

            final currentResult = await runHoriHori(['current']);
            expect(currentResult.stdout, value);
          }));
    });

    group('hori-hori updated', () {
      test('Returns 1 if the versions are the same', () async {
        final updatedResult = await runHoriHori(['updated', '1.2.3+4']);

        expect(updatedResult.exitCode, 1);
      });

      test('Returns 1 if the given version is newer than the current version',
          () async {
        expect((await runHoriHori(['updated', '1.2.4'])).exitCode, 1);
        expect((await runHoriHori(['updated', '1.3.0'])).exitCode, 1);
        expect((await runHoriHori(['updated', '2.0.0'])).exitCode, 1);
        expect((await runHoriHori(['updated', '1.2.3+5'])).exitCode, 1);
      });

      test('Returns 0 if the given version is older than the current version',
          () async {
        expect((await runHoriHori(['updated', '1.2.2'])).exitCode, 0);
        expect((await runHoriHori(['updated', '1.0.0'])).exitCode, 0);
        expect((await runHoriHori(['updated', '0.2.0'])).exitCode, 0);
        expect((await runHoriHori(['updated', '1.2.3+3'])).exitCode, 0);
      });

      test('Fails if no argument provided', () async {
        final updatedResult = await runHoriHori(['updated']);

        expect(updatedResult.exitCode, 1);
        expect(updatedResult.stderr, isNotEmpty);
      });

      test('Fails if 2+ arguments provided', () async {
        final updatedResult = await runHoriHori(['updated', 'one', 'two']);

        expect(updatedResult.exitCode, 1);
        expect(updatedResult.stderr, isNotEmpty);
      });

      test('Fails if bad argument provided', () async {
        final updatedResult = await runHoriHori(['updated', 'bad']);

        expect(updatedResult.exitCode, 1);
        expect(updatedResult.stderr, isNotEmpty);
      });
    });
  });
}
