import 'package:task_monitor/task_monitor.dart';

class SynchCounts {
  final int created;
  final int updated;
  final int deleted;

  SynchCounts({
    required this.created,
    required this.updated,
    required this.deleted,
  });
}

TaskMonitor monitor = TaskMonitor();

Future<void> taskOne() async {
  monitor.getTask('task1')!.start();
  await Future.delayed(const Duration(seconds: 3));
  monitor.getTask('task1')!.complete(
    message: 'Task One has completed',
    data: {
      'counts': SynchCounts(
        created: 6,
        updated: 3,
        deleted: 2,
      )
    }
  );
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
      if(update.hasData && update.data.containsKey('counts') && update.data['counts'] is SynchCounts) {
        SynchCounts? counts = update.getData<SynchCounts>('counts');
        print('Created ${counts!.created} records, updated ${counts!.updated} and deleted ${counts!.deleted}');
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

  await Future.delayed(const Duration(seconds: 10));

  print('Task One last ran ${monitor.history.getTimeSinceLastCompleted('task1')!.inMilliseconds}ms ago');

}
