import 'package:task_monitor/task_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    //final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('Creating tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );
      expect(task.id, 'task1');
      expect(task.status, TaskStatus.pending);
      expect(task.isPending, true);
      expect(task.isStarted, false);
      expect(task.isFailed, false);
      expect(task.isCompleted, false);
    });
    test('can start tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(historyEnabled: false,),
      );
      task.start();
      expect(task.isPending, false);
      expect(task.isStarted, true);
      expect(task.isRunning, true);
    });
    test('cannot start running tasks by default', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.started,
        monitor: TaskMonitor(historyEnabled: false,),
      );
      expect(() => task.start(), throwsA(TypeMatcher<TaskCannotStart>()));
    });
    test('can start running tasks if allowed to be concurrent', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.started,
        monitor: TaskMonitor(historyEnabled: false,),
        allowConcurrent: true,
      );
      task.start();
      expect(task.isStarted, true);
    });
    test('can complete tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(historyEnabled: false,),
      );
      task.start();
      task.complete();
      expect(task.isPending, false);
      expect(task.isStarted, false);
      expect(task.isCompleted, true);
      expect(task.isCompletedOrFailed, true);
    });
    test('cannot complete pending tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );      
      expect(() => task.complete(), throwsA(TypeMatcher<TaskNotStarted>()));
    });
    test('can fail tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(historyEnabled: false,),
      );
      task.start();
      task.fail();
      expect(task.isPending, false);
      expect(task.isStarted, false);
      expect(task.isCompleted, false);
      expect(task.isFailed, true);
      expect(task.isCompletedOrFailed, true);
    });
    test('cannot fail pending tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );      
      expect(() => task.fail(), throwsA(TypeMatcher<TaskNotStarted>()));
    });
    test('the task name is the ID if not provided', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );      
      expect(task.name, 'task1');
    });
    test('can assign a name to a task', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
        name: 'First task'
      );      
      expect(task.name, 'First task');
    });
    test('can associate data with tasks', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );      
      expect(task.data, isA<Map>());
      task.data['foo'] = 'bar';
      expect(task.data['foo'], 'bar');
      task.data['value'] = 123;
      expect(task.data['value'], 123);
      
    });
    test('provides a string representation', () {
      Task task = Task(
        id: 'task1',
        status: TaskStatus.pending,
        monitor: TaskMonitor(),
      );      
      expect(task.toString(), isA<String>());
      expect(task.toString(), 'task1: pending');
    });
  });
}
