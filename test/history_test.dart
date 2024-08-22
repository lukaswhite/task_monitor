import 'package:task_monitor/src/task_status.dart';
import 'package:task_monitor/task_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('Maintaining history', () {    
    test('History is enabled by default', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.historyEnabled, true);
    });
    test('Can disable history in constructor', () {
      TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
      expect(monitor.historyEnabled, false);
    });
    test('Creates record when task started', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.start(id: 'task1');
      expect(monitor.getHistory('task1'), isA<List>());
      expect(monitor.getHistory('task1').isNotEmpty, true);
      expect(monitor.getHistory('task1').length, 1);
      expect(monitor.getHistory('task1').last.taskId, 'task1');
      expect(monitor.getHistory('task1').last.status, TaskStatus.started);
      expect(monitor.getHistory('task1').last.startedAt, isNotNull);
      expect(monitor.getHistory('task1').last.startedAt, isA<DateTime>());
      expect(monitor.getHistory('task1').last.duration, isNull);
      expect(monitor.getHistory('task1').last.completedAt, isNull);
      expect(monitor.getHistory('task1').last.message, isNull);
    }); 
    test('Does not creates record when task started if history is disabled', () {
      TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
      monitor.start(id: 'task1');
      expect(monitor.getHistory('task1'), isA<List>());
      expect(monitor.getHistory('task1').isEmpty, true);
    }); 
    test('Updates record when task completed', () {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.start(id: 'task1');
      task.complete(message: 'Task completed');
      expect(monitor.getHistory('task1'), isA<List>());
      expect(monitor.getHistory('task1').isNotEmpty, true);
      expect(monitor.getHistory('task1').length, 1);
      expect(monitor.getHistory('task1').last.taskId, 'task1');
      expect(monitor.getHistory('task1').last.status, TaskStatus.completed);
      expect(monitor.getHistory('task1').last.duration, isNotNull);
      expect(monitor.getHistory('task1').last.duration, isA<Duration>());
      expect(monitor.getHistory('task1').last.completedAt, isNotNull);
      expect(monitor.getHistory('task1').last.completedAt, isA<DateTime>());
      expect(monitor.getHistory('task1').last.message, 'Task completed');
    });
    test('Updates record when task failed', () {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.start(id: 'task1');
      task.fail(error: Error());
      expect(monitor.getHistory('task1'), isA<List>());
      expect(monitor.getHistory('task1').isNotEmpty, true);
      expect(monitor.getHistory('task1').length, 1);
      expect(monitor.getHistory('task1').last.taskId, 'task1');
      expect(monitor.getHistory('task1').last.status, TaskStatus.failed);
      expect(monitor.getHistory('task1').last.duration, isNotNull);
      expect(monitor.getHistory('task1').last.duration, isA<Duration>());
      expect(monitor.getHistory('task1').last.completedAt, isNotNull);
      expect(monitor.getHistory('task1').last.completedAt, isA<DateTime>());
      expect(monitor.getHistory('task1').last.error, isNotNull);
    }); 
  });
  group('Retrieving history', () {    
    test('Can get history by ID', () {
      TaskMonitor monitor = TaskMonitor();
      expect(monitor.historyEnabled, true);
      Task task = monitor.start(id: 'task1');
      task.fail(error: Error());
      task.start();
      task.complete();
      task.start();
      task.complete();
      task.start();
      expect(monitor.getHistory('task1'), isA<List>());
      expect(monitor.getHistory('task1').length, 4);
      expect(monitor.getHistory('task1').first.status, TaskStatus.failed);
      expect(monitor.getHistory('task1').last.status, TaskStatus.started);
    });
    test('Getting history fails if task not found', () {
      TaskMonitor monitor = TaskMonitor();
      expect(() => monitor.getHistory('task'), throwsA(TypeMatcher<TaskNotFound>()));
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
      expect(monitor.getHistory('task1').length, 2);
      expect(monitor.getHistory('task2').length, 2);
      monitor.clearHistory('task1');
      expect(monitor.getHistory('task1').length, 0);
      expect(monitor.getHistory('task2').length, 2);
      monitor.clearHistory('task2');
      expect(monitor.getHistory('task1').length, 0);
      expect(monitor.getHistory('task2').length, 0);
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
      expect(monitor.getHistory('task1').length, 2);
      expect(monitor.getHistory('task2').length, 2);
      monitor.clearAllHistory();
      expect(monitor.getHistory('task1').length, 0);
      expect(monitor.getHistory('task2').length, 0);
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
      expect(monitor.getHistory('task1').length, 100);
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
      expect(monitor.getHistory('task1').length, 50);
      expect(monitor.getHistory('task1').last.status, TaskStatus.started);
    });
  });
}