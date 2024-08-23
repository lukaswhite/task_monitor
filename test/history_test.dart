import 'package:task_monitor/task_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('Maintaining history', () {    
    test('History is enabled by default', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.historyEnabled, true);
      expect(monitor.history.isEnabled, true);
      expect(monitor.history.isDisabled, false);
    });
    test('Can disable history in constructor', () {
      TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
      expect(monitor.historyEnabled, false);
      expect(monitor.history.isEnabled, false);
      expect(monitor.history.isDisabled, true);
    });
    test('Can disable history', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.history.disable();
      expect(monitor.history.isEnabled, false);
      expect(monitor.history.isDisabled, true);
    });
    test('Can enable history', () {
      TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
      monitor.history.enable();
      expect(monitor.history.isEnabled, true);
      expect(monitor.history.isDisabled, false);
    });
    test('Creates record when task started', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.start(id: 'task1');
      expect(monitor.history.getForTask('task1'), isA<List>());
      expect(monitor.history.getForTask('task1').isNotEmpty, true);
      expect(monitor.history.getForTask('task1').length, 1);
      expect(monitor.history.getForTask('task1').last.taskId, 'task1');
      expect(monitor.history.getForTask('task1').last.status, TaskStatus.started);
      expect(monitor.history.getForTask('task1').last.startedAt, isNotNull);
      expect(monitor.history.getForTask('task1').last.startedAt, isA<DateTime>());
      expect(monitor.history.getForTask('task1').last.duration, isNull);
      expect(monitor.history.getForTask('task1').last.completedAt, isNull);
      expect(monitor.history.getForTask('task1').last.message, isNull);
    }); 
    test('Does not creates record when task started if history is disabled', () {
      TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
      monitor.start(id: 'task1');
      expect(monitor.history.getForTask('task1'), isA<List>());
      expect(monitor.history.getForTask('task1').isEmpty, true);
    }); 
    test('Updates record when task completed', () {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.start(id: 'task1');
      task.complete(message: 'Task completed');
      expect(monitor.history.getForTask('task1'), isA<List>());
      expect(monitor.history.getForTask('task1').isNotEmpty, true);
      expect(monitor.history.getForTask('task1').length, 1);
      expect(monitor.history.getForTask('task1').last.taskId, 'task1');
      expect(monitor.history.getForTask('task1').last.status, TaskStatus.completed);
      expect(monitor.history.getForTask('task1').last.duration, isNotNull);
      expect(monitor.history.getForTask('task1').last.duration, isA<Duration>());
      expect(monitor.history.getForTask('task1').last.completedAt, isNotNull);
      expect(monitor.history.getForTask('task1').last.completedAt, isA<DateTime>());
      expect(monitor.history.getForTask('task1').last.message, 'Task completed');
    });
    test('Updates record when task failed', () {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.start(id: 'task1');
      task.fail(error: Exception());
      expect(monitor.history.getForTask('task1'), isA<List>());
      expect(monitor.history.getForTask('task1').isNotEmpty, true);
      expect(monitor.history.getForTask('task1').length, 1);
      expect(monitor.history.getForTask('task1').last.taskId, 'task1');
      expect(monitor.history.getForTask('task1').last.status, TaskStatus.failed);
      expect(monitor.history.getForTask('task1').last.duration, isNotNull);
      expect(monitor.history.getForTask('task1').last.duration, isA<Duration>());
      expect(monitor.history.getForTask('task1').last.completedAt, isNotNull);
      expect(monitor.history.getForTask('task1').last.completedAt, isA<DateTime>());
      expect(monitor.history.getForTask('task1').last.error, isNotNull);
    }); 
  });
  group('Ignoring tasks', () {    
    test('Can get history by ID', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.history.ignore('task1');
      Task task = monitor.create(id: 'task1');
      task.start();
      expect(monitor.history.getByTaskId('task1'), isNull);
      task.fail();
      expect(monitor.history.getByTaskId('task1'), isNull);
    });
  });
  group('Retrieving history', () {    
    test('Can get history by ID', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.historyEnabled, true);
      Task task = monitor.start(id: 'task1');
      task.fail(error: Exception());
      task.start();
      task.complete();
      task.start();
      task.complete();
      task.start();
      expect(monitor.history.getForTask('task1'), isA<List>());
      expect(monitor.history.getForTask('task1').length, 4);
      expect(monitor.history.getForTask('task1').first.status, TaskStatus.failed);
      expect(monitor.history.getForTask('task1').last.status, TaskStatus.started);
    });    
  });
  group('Clearing history', () {    
    test('Can clear history for a specfic task', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.complete();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.getForTask('task1').length, 2);
      expect(monitor.history.getForTask('task2').length, 2);
      monitor.history.clear('task1');
      expect(monitor.history.getForTask('task1').length, 0);
      expect(monitor.history.getForTask('task2').length, 2);
      monitor.history.clear('task2');
      expect(monitor.history.getForTask('task1').length, 0);
      expect(monitor.history.getForTask('task2').length, 0);
    });
    test('Can clear all history', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.complete();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.getForTask('task1').length, 2);
      expect(monitor.history.getForTask('task2').length, 2);
      monitor.history.clearAll();
      expect(monitor.history.getForTask('task1').length, 0);
      expect(monitor.history.getForTask('task2').length, 0);
    });
    test('Can clear up to a certain time', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 10)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 8)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 6)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 5)), 
      ));
      expect(monitor.history.getForTask('task1').length, 4);
      monitor.history.clearTo('task1', Duration(days: 7));
      expect(monitor.history.getForTask('task1').length, 2);
    });
    test('Can clear all up to a certain time', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 10)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 8)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 6)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 5)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task2', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 11)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task2', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 9)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task2', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 8)), 
      ));
      monitor.history.add(TaskExecution(
        taskId: 'task2', 
        status: TaskStatus.completed, 
        startedAt: DateTime.now().subtract(Duration(days: 4)), 
      ));
      expect(monitor.history.getForTask('task1').length, 4);
      expect(monitor.history.getForTask('task2').length, 4);
      monitor.history.clearAllTo(Duration(days: 7));
      expect(monitor.history.getForTask('task1').length, 2);
      expect(monitor.history.getForTask('task2').length, 1);
    });
  });
  group('Limiting history history', () {    
    test('Limits disabled by default', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.historyLimit, null);
      Task task1 = monitor.create(id: 'task1');
      for(int i = 0; i < 100; i++) {
        task1.start();
        task1.complete();
      }
      expect(monitor.history.getForTask('task1').length, 100);
    });
    test('Can limit history', () {
      TaskMonitor monitor = TaskMonitor(historyLimit: 50,);
      expect(monitor.historyLimit, 50);
      Task task1 = monitor.create(id: 'task1');
      for(int i = 0; i < 100; i++) {
        task1.start();
        task1.complete();
      }
      task1.start();
      expect(monitor.history.getForTask('task1').length, 50);
      expect(monitor.history.getForTask('task1').last.status, TaskStatus.started);
    });
  });
  group('Last completed', () {    
    test('Can get last completed task', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.complete();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.lastCompleted('task1'), isNotNull);
      expect(monitor.history.lastCompleted('task1')!.taskId, 'task1');
      expect(monitor.history.lastCompleted('task1')!.status, TaskStatus.completed);
    });
    test('Last completed task can be null', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.fail();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.lastCompleted('task2'), isNull);
    });
    test('Can get last completed time', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.complete();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.lastCompletedAt('task1'), isNotNull);
      expect(monitor.history.lastCompletedAt('task1'), isA<DateTime>());      
    });
    test('Last completed time can be null', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.fail();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.lastCompleted('task2'), isNull);
    });
    test('Can get time since last completed', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.complete();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.getTimeSinceLastCompleted('task1'), isNotNull);
      expect(monitor.history.getTimeSinceLastCompleted('task1'), isA<Duration>());      
    });
    test('Last completed time can be null', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.fail();
      task1.start();
      task2.start();
      task1.fail();
      expect(monitor.history.getTimeSinceLastCompleted('task2'), isNull);
    });
  });
  group('Updates', () {
    test('Has a stream of updates', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.history.executions, isNotNull);
      expect(monitor.history.executions, isA<Stream>());
    });
  });
  group('Serialization', () {
    test('Can serialize started tasks', () {
      TaskExecution execution = TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.started,
        startedAt: DateTime(2024, 10, 3, 11, 23, 45),
      );
      Map<String, dynamic> json = execution.toJson();
      expect(json['taskId'], 'task1');
      expect(json['status'], 'started');
      expect(json['startedAt'], '2024-10-03T11:23:45.000');
      expect(json['duration'], null);
      expect(json['error'], null);
    });
    test('Can serialize completed tasks', () {
      TaskExecution execution = TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed,
        startedAt: DateTime(2024, 10, 3, 11, 23, 45),
        duration: Duration(milliseconds: 1234),
        message: 'Ran okay'
      );
      Map<String, dynamic> json = execution.toJson();
      expect(json['taskId'], 'task1');
      expect(json['status'], 'completed');
      expect(json['startedAt'], '2024-10-03T11:23:45.000');
      expect(json['duration'], 1234);
      expect(json['message'], 'Ran okay');
    });
    test('Can serialize failed tasks', () {
      TaskExecution execution = TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.failed,
        startedAt: DateTime(2024, 10, 3, 11, 23, 45),
        duration: Duration(milliseconds: 1234),
        error: Exception('This is an error')
      );
      Map<String, dynamic> json = execution.toJson();
      expect(json['taskId'], 'task1');
      expect(json['status'], 'failed');
      expect(json['startedAt'], '2024-10-03T11:23:45.000');
      expect(json['duration'], 1234);
      expect(json['error'], 'Exception: This is an error');
    });
    test('Can create started tasks from JSON', () {
      TaskExecution execution = TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.started,
        startedAt: DateTime(2024, 10, 3, 11, 23, 45),
      );
      TaskExecution rehydrated = TaskExecution.fromJson(execution.toJson());
      expect(rehydrated.taskId, 'task1');
      expect(rehydrated.status, TaskStatus.started);
      expect(rehydrated.startedAt, DateTime(2024, 10, 3, 11, 23, 45));
    });
    test('Can create completed tasks from JSON', () {
      TaskExecution execution = TaskExecution(
        taskId: 'task1', 
        status: TaskStatus.completed,
        startedAt: DateTime(2024, 10, 3, 11, 23, 45),
        duration: Duration(milliseconds: 1234),
        message: 'Ran okay'
      );
      TaskExecution rehydrated = TaskExecution.fromJson(execution.toJson());
      expect(rehydrated.taskId, 'task1');
      expect(rehydrated.status, TaskStatus.completed);
      expect(rehydrated.startedAt, DateTime(2024, 10, 3, 11, 23, 45));
      expect(rehydrated.duration, isNotNull);
      expect(rehydrated.duration, isA<Duration>());
      expect(rehydrated.duration!.inMilliseconds, 1234);
      expect(rehydrated.message, 'Ran okay');
    });
    test('Can serialize all', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.start(id: 'task1');
      task1.complete();
      Task task2 = monitor.start(id: 'task2');
      task2.fail();
      task1.start();
      task2.start();
      task1.fail();
      Map<String, dynamic> json = monitor.history.toJson();
      expect(json.keys.contains('task1'), true);      
      expect(json['task1'].length, 2);
      expect(json['task1'].first['taskId'], 'task1');
      expect(json['task1'].first['status'], 'completed');
      expect(json['task1'].last['status'], 'failed');
      expect(json.keys.contains('task2'), true);
      expect(json['task2'].length, 2);
      expect(json['task2'].first['taskId'], 'task2');
    });
  });
}