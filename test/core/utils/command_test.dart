import 'dart:async';

import 'package:atril/core/utils/command.dart';
import 'package:atril/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Command0', () {
    test('exposes running state, result state, and notifications', () async {
      final completer = Completer<Result<int>>();
      final command = Command0<int>(() => completer.future);
      final states = <({bool running, bool completed, bool error, Result? result})>[];
      command.addListener(() {
        states.add((
          running: command.running,
          completed: command.completed,
          error: command.error,
          result: command.result,
        ));
      });

      final execution = command.execute();

      expect(command.running, isTrue);
      expect(command.result, isNull);
      completer.complete(const Result.ok(42));
      await execution;

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(command.result, isA<Ok<int>>().having((result) => result.value, 'value', 42));
      expect(states, hasLength(2));
      expect(states.first.running, isTrue);
      expect(states.last.running, isFalse);
    });

    test('ignores re-entrant executions while running', () async {
      final completer = Completer<Result<int>>();
      var calls = 0;
      final command = Command0<int>(() {
        calls++;
        return completer.future;
      });

      final firstExecution = command.execute();
      await command.execute();
      completer.complete(const Result.ok(1));
      await firstExecution;

      expect(calls, 1);
    });

    test('clearResult removes consumed result and notifies listeners', () async {
      var notifications = 0;
      final command = Command0<int>(() async => Result.error(Exception('boom')));
      command.addListener(() => notifications++);

      await command.execute();
      expect(command.error, isTrue);

      command.clearResult();

      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(notifications, 3);
    });
  });

  group('Command arguments', () {
    test('passes one, two, and three arguments to the wrapped action', () async {
      final command1 = Command1<String, int>((value) async => Result.ok('one:$value'));
      final command2 = Command2<String, int, int>((left, right) async => Result.ok('two:${left + right}'));
      final command3 = Command3<String, int, int, int>(
        (left, middle, right) async => Result.ok('three:${left + middle + right}'),
      );

      await command1.execute(3);
      await command2.execute(2, 5);
      await command3.execute(1, 2, 4);

      expect(command1.result, isA<Ok<String>>().having((result) => result.value, 'value', 'one:3'));
      expect(command2.result, isA<Ok<String>>().having((result) => result.value, 'value', 'two:7'));
      expect(command3.result, isA<Ok<String>>().having((result) => result.value, 'value', 'three:7'));
    });
  });
}
