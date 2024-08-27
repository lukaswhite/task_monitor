import 'package:task_monitor/task_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('Task monitor', () {
    //final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('Can create pending tasks', () {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.create(id: 'task1');
      expect(task.id, 'task1');
      expect(task.isPending, true);
      expect(monitor.totalTasks, 1);
      expect(monitor.pending, isA<List>());
      expect(monitor.pending.length, 1);
      expect(monitor.pending.first, isA<Task>());
      expect(monitor.pending.first.id, 'task1');
    });
    test('Cannot create pending task if ID in use', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.create(id: 'task1');
      monitor.create(id: 'task2');
      expect(() => monitor.create(id: 'task1'), throwsA(TypeMatcher<DuplicateTaskId>()));
    });
    test('Can get or create by ID', () {
      TaskMonitor monitor = TaskMonitor();
      Task task1 = monitor.getOrCreate(id: 'task', name: 'Task One');
      expect(task1.id, 'task');
      expect(task1.name, 'Task One');
      expect(monitor.totalTasks, 1);
      Task task2 = monitor.getOrCreate(id: 'task', name: 'Task Two');
      expect(task2.id, 'task');
      expect(task2.name, 'Task One');
      expect(monitor.totalTasks, 1);
    });
    test('Can create and start tasks', () {
      TaskMonitor monitor = TaskMonitor();
      //monitor.updates.listen((update) => print(update.task));
      Task task = monitor.start(id: 'task1');
      expect(task.id, 'task1');
      expect(task.isStarted, true);
      expect(monitor.totalTasks, 1);
      expect(monitor.running, isA<List>());
      expect(monitor.running.length, 1);
      expect(monitor.running.first, isA<Task>());
      expect(monitor.running.first.id, 'task1');
    });
    test('Cannot create and start task if ID in use', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.start(id: 'task1');
      monitor.create(id: 'task2');
      expect(() => monitor.start(id: 'task1'), throwsA(TypeMatcher<DuplicateTaskId>()));
    });
    test('Can get tasks by ID', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.create(id: 'task1');
      expect(monitor.getTask('task1'), isA<Task>());
      expect(monitor.getTask('task1')!.id, 'task1');
    });
    test('Get tasks by ID returns null if not found', () {
      TaskMonitor monitor = TaskMonitor();
      monitor.create(id: 'task1');
      expect(monitor.getTask('task2'), isNull);
    });
    test('Can get a list of task IDs', () {
      TaskMonitor monitor = TaskMonitor();
      monitor..create(id: 'task1')..create(id: 'task2')..start(id: 'task3')..create(id: 'task4');
      expect(monitor.taskIds, isA<List>());
      expect(monitor.taskIds.length, 4);
      expect(monitor.taskIds.contains('task3'), true);
    });
    test('Can generate a unique ID', () {
      TaskMonitor monitor = TaskMonitor();
      for(var i = 0; i < 1000; i++) {
        String id = monitor.uniqueId();
        expect(monitor.taskIds.contains(id), false);
        expect(id.startsWith('task-'), true);
      }
    });
    test('Can generate a unique ID with a prefix', () {
      TaskMonitor monitor = TaskMonitor();
      for(var i = 0; i < 1000; i++) {
        String id = monitor.uniqueId(prefix: 'mytask');
        expect(monitor.taskIds.contains(id), false);
        expect(id.startsWith('mytask-'), true);
      }
    });
    test('Can run functions that complete', () async {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.create(id: 'task');
      Task executed = await monitor.run(task, () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return true;
      });
      expect(executed.isCompleted, true);
      expect(monitor.history.getForTask('task').length, 1);
      expect(monitor.history.last('task')!.status, TaskStatus.completed);
    });
    test('Can run functions that fail', () async {
      TaskMonitor monitor = TaskMonitor();
      Task task = monitor.create(id: 'task');
      Task executed = await monitor.run(task, () async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception();
      });
      expect(executed.isFailed, true);
      expect(monitor.history.getForTask('task').length, 1);
      expect(monitor.history.last('task')!.error != null, true);
      expect(monitor.history.last('task')!.status, TaskStatus.failed);
    });
    test('Can get tasks with a particular tag', () async {
      TaskMonitor monitor = TaskMonitor();
      monitor.create(id: 'task1', tags: ['network']);
      monitor.create(id: 'task2');
      monitor.create(id: 'task3', tags: ['sqlite']);
      monitor.create(id: 'task4', tags: ['network', 'sqlite']);
      monitor.create(id: 'task5', tags: ['network', 'my-api']);
      monitor.create(id: 'task6', tags: ['network', 'my-api']);
      expect(monitor.taggedWith('network').length, 4);
      expect(monitor.taggedWith('sqlite').length, 2);
    });
  });
}
