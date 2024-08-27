import 'package:task_monitor/task_monitor.dart';
import 'package:task_monitor/src/tasks_list.dart';
import 'package:test/test.dart';

void main() {
  group('List basics', () {    
    test('It is a list', () {
      TasksList tasks = TasksList();
      expect(tasks, isA<List>());
      expect(tasks, isA<List<TaskExecution>>());
    });
    test('Can add to it', () {
      TasksList tasks = TasksList();
      tasks.add(TaskExecution(taskId: 'task1', status: TaskStatus.completed));
      expect(tasks.length, 1);
      expect(tasks.first, isA<TaskExecution>());
      expect(tasks.first.taskId, 'task1');
    });
    test('Can add multiple to it', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task2', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task2', status: TaskStatus.failed),
      ]);
      expect(tasks.length, 5);
      expect(tasks.first, isA<TaskExecution>());
      expect(tasks.first.taskId, 'task1');
      expect(tasks.last.taskId, 'task2');
    });
  });
  group('Filtering by status', () {    
    test('Can get completed tasks', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.started),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
      ]);
      expect(tasks.completed().length, 5);
      expect(tasks.completed().first.isCompleted, true);
    });
    test('Can get failed tasks', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.started),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
      ]);
      expect(tasks.failed().length, 4);
      expect(tasks.failed().first.isFailed, true);
    });
    test('Can get completed or failed tasks', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.started),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
      ]);
      expect(tasks.completedOrFailed().length, 9);
      expect(tasks.completedOrFailed().first.isCompleted, true);
      expect(tasks.completedOrFailed().last.isFailed, true);
    });
  });
  group('Status as percentages', () {    
    test('Can get percent completed', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.started),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
      ]);
      expect(tasks.percentageCompleted(), isA<double>());
      expect(tasks.percentageCompleted(), 50.0);
    });
    test('Can get percent failed', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
        TaskExecution(taskId: 'task1', status: TaskStatus.completed),
        TaskExecution(taskId: 'task1', status: TaskStatus.started),
        TaskExecution(taskId: 'task1', status: TaskStatus.failed),
      ]);
      expect(tasks.percentageFailed(), isA<double>());
      expect(tasks.percentageFailed(), 40);
    });
    test('Percentage zero for empty list', () {
      TasksList tasks = TasksList();
      expect(tasks.percentageCompleted(), 0);
      expect(tasks.percentageFailed(), 0);
    });
  });
  group('Filtering by timestamp', () {    
    test('Can get tasks since a certain time', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 90,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 80,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 70,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 60,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 50,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 40,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 30,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 20,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 10,))
        ),
      ]);
      expect(
        tasks.since(
          DateTime.now().subtract(const Duration(minutes: 45))
        ).length, 4);
      expect(
        tasks.failedSince(
          DateTime.now().subtract(const Duration(minutes: 45))
        ).length, 2);
    });
    test('Can get tasks within a certain duration', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 90,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 80,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 70,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 60,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 50,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 40,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 30,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 20,))
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 10,))
        ),
      ]);
      expect(
        tasks.inTimePeriod(const Duration(minutes: 45)).length, 4);
    });
  });
  group('Task durations', () {    
    test('Can get maximum duration', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 100,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 80,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 110,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.started, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),          
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 300,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 50,)
        ),
      ]);
      expect(tasks.maxTimeTaken()!.inMilliseconds, 300);
    });
    test('Can get average time taken', () {
      TasksList tasks = TasksList();
      tasks.addAll([
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 100,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.failed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 80,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 110,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.started, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),          
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 300,)
        ),
        TaskExecution(
          taskId: 'task1', 
          status: TaskStatus.completed, 
          startedAt: DateTime.now().subtract(const Duration(minutes: 100,)),
          duration: const Duration(milliseconds: 50,)
        ),
      ]);
      expect(tasks.averageTimeTaken().inMilliseconds, 128);
    });
  });
}