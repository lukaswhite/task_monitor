import 'package:task_monitor/task_monitor.dart';

TaskMonitor monitor = TaskMonitor();

Future<void> taskOne() async {
  monitor.getTask('task1')!.start();
  await Future.delayed(const Duration(seconds: 3));
  monitor.getTask('task1')!.complete(message: 'Task One has completed');
}

Future<void> taskTwo() async {
  if(monitor.getTask('task2')!.isRunning) {
    print('Task two is already running, skipping');
    return;
  }
  monitor.getTask('task2')!.start();
  await Future.delayed(const Duration(seconds: 2));
  monitor.getTask('task2')!.complete();
}

Future<void> taskThree() async {
  monitor.getTask('task3')!.start();
  await Future.delayed(const Duration(seconds: 1));
  monitor.getTask('task3')!.fail(message: 'Task Three has failed :(');
}

void main() async {

  monitor.create(id: 'task1');
  monitor.create(id: 'task2');
  monitor.create(id: 'task3');

  monitor.updates.listen(
    (update) {
      print('${update.task.id}: ${update.status.name}');
      if(update.hasMessage) {
        print(' - ${update.message}');
      }
    }
  );

  monitor.failedUpdates.listen(
    (update) => print('${update.task.id} has failed!')
  );

  monitor.completedUpdates.listen(
    (update) => print('${update.task.id} took ${update.duration!.inMilliseconds}ms')
  );

  await Future.wait([
    taskOne(),
    taskTwo(),
    taskTwo(),
    taskThree(),    
  ]);

  print('Task One last ran ${DateTime.now().difference(monitor.getHistory('task1').first!.completedAt!).inMilliseconds}ms ago');

}
