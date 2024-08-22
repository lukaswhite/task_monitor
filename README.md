# Task Monitor

A simple task monitoring package for Dart or Flutter.

## Overview

This package helps track the execution of non-trivial tasks; for example fetching data from an API, downloading some files or synnchronising data. 

In one sense, it's an abstraction over your logging framework of choice, providing an interface for recording logs detailing tasks that have started, completed or failed.

It provides a stream with updates of the status of tasks. Suppose you have a number of tasks that need to run on startup or registration; using the stream you could update users as to what's happening.

By default it stores a record of when tasks were run, whether they suceeded or failed, how long they took and any additional information that may be useful. You can disable this feature if you prefer.

> Note that this is only stored in memory, but it's easy to provide a storage mechanism.

It also allows you to ensure that the same task cannot be run more than once at the same time. This is particularly useful if, for example, you use a package like [cron](https://pub.dev/packages/cron) to schedule regular maintenance tasks. Should a task take longer than expected to run, you may opt to skip it on the next scheduled run.

## Fundamentals

In the context of this package, a task is simply a representation of some work; it doesn't run any task-specific code; it's used for monitoring purposes. 

A task has a unique ID, an optional name &mdash; it defaults to the ID &mdash; and you can attach additional data to it.

Tasks have one of four statuses:

`pending`: The task is idle, i.e. it hasn't started. 

`started`: The task has started; i.e. it's currently running.

`completed`: The task ran successfully.

`failed`: The task failed to run. 

Typically you can only start a task if it's in the `pending`, `completed` or `failed` state.

## Creating a Task

Create a task like this:

```dart
import 'package:task_monitor/task_monitor.dart';

TaskMonitor monitor = TaskMonitor();
Task task = monitor.create(id: 'synch-data');
```

This registers a task with the provided ID in a `pending` state.

You can create a task and start it straight away:

```dart
TaskMonitor monitor = TaskMonitor();
Task task = monitor.start(id: 'synch-data');
```

You can also create a task only if it doesn't exist:

```dart
TaskMonitor monitor = TaskMonitor();
Task task = monitor.getOrCreate(id: 'synch-data');
```

You can retrieve a task at any time:

```dart
TaskMonitor monitor = TaskMonitor();
Task task = monitor.get('synch-data');
```

> This throws a `TaskNotFound` error if it's not been registered

You can check the status of a task:

```dart
TaskMonitor monitor = TaskMonitor();
Task task = monitor.get('synch-data');

if(task.isRunning) {}
if(task.isPending) {}
if(task.isCompleted) {}
if(task.isFailed) {}
if(task.isCompletedOrFailed) {}

```

## Starting a Task

We've seen above that you can create and start a task in one function call; oherwise do this:

```
task.start();
```

## Completing a Task

Once a task has finished, you should mark it as completed:

```
task.complete();
```

You can optionally provide a message:

```
task.complete(message: 'Synched $count records');
```

## Failing a Task

If a task fails to run for whatever reason, use the `fail()` method rather than `complete()`:

```
task.fail();
```

You can optionally provide a message:

```
task.fail(message: 'Failed to synch!);
```

You can optionally provide an error:

```
try {
    // do something
} catch (e) {
    task.fail(
        message: 'Failed to synch!,
        error: e,
    );
}
```

## Events

Whenever a task is started, completed or failed it adds an `Update` event to the `updates` stream.

```dart
TaskMonitor monitor = TaskMonitor();
Task task = monitor.create(id: 'synch-data');

monitor.updates.listen((update) => {
  if(update.status == TaskStatus.started) {
    logger.info('${update.task.name} has started');
  } else if(update.status == TaskStatus.completed) {
    logger.info('${update.task.name} ran in ${update.duration!.inMilliseconds}ms');
  } else if(update.status == TaskStatus.failed) {
    logger.error('${update.task.name} failed!');
    yourCustomErrorHandler.log(
      id: update.task.id,
      error: update.error,
    );
  }
})
```

## History

By default, the monitor keeps a running history of tasks being run. 

```dart
List<TaskExecution> history = monitor.getHistory('synch-data');
```

This provides:

 - The `taskId`
 - The `status`
 - When it started `startedAt`
 - The length of time it took, if it's `completed` or `failed` (`duration`)
 - When it finished `completedAt`, if it's `completed` or `failed`
 - An optional `message`
 - An optional `error`

For example, you can check whether the last execution completed successfully:

```dart
if(
    monitor.getHistory('synch-data').isNotEmpty() &&
    monitor.getHistory('synch-data').last.status == TaskStatus.completed
) {}
```

Or to find out when it last ran sucessfully:

```dart
if(
    monitor.getHistory('synch-data').isNotEmpty() &&
    monitor.getHistory('synch-data').last.status == TaskStatus.completed
) {
    if(DateTime.now().subtract(monitor.getHistory('synch-data').last.completedAt).inMinutes > 60) {
        // run again?
    }
}
```

Bear in mind that this stores the records in memory, so you may wish to create a storage mechanism by hooking into the `updates` stream.

You can disable history:

```dart
TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
```

You can limit the number of records. In the following example, the monitor will only keep hold of the last 2o executions:

```dart
TaskMonitor monitor = TaskMonitor(historyLimit: 20,);
```

You can clear the history for a given task, or for all tasks:

```dart
monitor.clearHistory('synch-data');
monitor.clearAllHistory();
```

## Example

The following example demonstrates a number of aspects:

> You'll find this in the `examples` folder

```dart
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

```

## Cron

Here's an example of how you might use this package with [cron](https://pub.dev/packages/cron). It ensures that a task will only run once at a given time.

```dart
import 'package:task_monitor/task_monitor.dart';
import 'package:cron/cron.dart';

TaskMonitor monitor = TaskMonitor();
Task task = monitor.getOrCreate(id: 'synch-data');

final cron = Cron();

cron.schedule(Schedule.parse('*/10 * * * *'), () async {
    if(!task.isRunning()) {
        task.start();
        // do something
        task.complete();
    } else {
        logger.warn('Scheduled task is already running - perhaps reduce the frequency?');
    }
});

```