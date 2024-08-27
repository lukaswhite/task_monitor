# Task Monitor

A simple task monitoring package for Dart or Flutter.

## Features

* Monitor running tasks
* Check if a task is currently running
* Monitor tasks that have completed or failed
* Store a history of task execution
* Determine when a task was last run, and whether or not it suceeded

## Quick Start

```dart
import 'package:task_monitor/task_monitor.dart';

TaskMonitor monitor = TaskMonitor();
Task task = monitor.create(id: 'synch-data');

monitor.updates.listen((update) => print('${update.task.id}: ${update.status.name}'));

if(!task.isRunning) {
  task.start();
  try {
    // do something
    task.complete();
  } on Exception catch (e) {
    task.failed(error: e,);
  }
}
```

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

You can let the monitor create an ID for you:

```dart
monitor.create(id: monitor.monitor.uniqueId());
// id e.g. task-12345
```

You can provide a prefix:

```dart
monitor.create(id: monitor.monitor.uniqueId(prefix: 'fetch'));
// id e.g. fetch-12345
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

You can also attach arbitrary data:

```dart
task.complete(
  data: {
    'num_records': 123,
  },
);
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
} on Exception catch(e){
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
    logger.finer('${update.task.name} has started');
  } else if(update.status == TaskStatus.completed) {
    logger.fine('${update.task.name} ran in ${update.duration!.inMilliseconds}ms');
  } else if(update.status == TaskStatus.failed) {
    logger.severe('${update.task.name} failed!');
    yourCustomErrorHandler.log(
      id: update.task.id,
      error: update.error,
    );
  }
});
```
> Note that in the above example, `logger` comes from the [logging](https://pub.dev/packages/logging) package; see the Miscellany section for more details.

## History

By default, the monitor keeps a running history of tasks being run. 

E.g. to get records for a particular task:

```dart
List<TaskExecution> history = monitor.getForTask('synch-data');
```

This provides a list of objects containing the following properties:

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
    monitor.getForTask('synch-data').isNotEmpty() &&
    monitor.getForTask('synch-data').last.status == TaskStatus.completed
) {}
```

Or to find out when it last ran sucessfully:

```dart
DateTime? lastSuccess = monitor.history.lastCompletedAt('synch-data');
```

Bear in mind that this stores the records in memory, so you may wish to create a storage mechanism by hooking into the `executions` stream on `monitor.history`.

You can disable history when creating a task monitor:

```dart
TaskMonitor monitor = TaskMonitor(historyEnabled: false,);
```

At a later time:

```dart
monitor.history.disable();
```

Re-enable like so:

```dart
monitor.history.enable();
```

You can limit the number of records. In the following example, the monitor will only keep hold of the last 2o executions:

```dart
TaskMonitor monitor = TaskMonitor(historyLimit: 20,);
```

You can clear the history for a particular task or all tasks. 

```dart
monitor.history.clear('synch-data');
monitor.history.clearAll();
```

You can do the similar, but discarding records where the last was started prior to the specified time. For example, to clear records from more than seven days ago:

```dart
monitor.history.clearTo('synch-data', Duration(days: 7));
monitor.history.clearAllTo(Duration(days: 7));
```

> It might be a good idea to use a package like [cron](https://pub.dev/packages/cron) to do this periodically.

## Querying history

The following returns records for a particular task:

```dart
TasksList tasks = monitor.history.getForTask('synch-data');
```

Note the return type; it's a specialized list that includes a bunch of methods for filtering and querying it.

For example, to get records of a task having failed:

```dart
TasksList tasks = monitor.history.getForTask('synch-data').failed();
```

To get records of a task having failed in the last 24 hours:

```dart
TasksList tasks = monitor.history.getForTask('synch-data').failedInTimePerdiod(const Duration(hours: 24,));
```

To find out how long, on average, as task takes to complete:

```dart
Duration max = monitor.history.getForTask('synch-data')
  .completed()
  .averageTimeTaken();
```

A more complex example; the following looks at the successful executions of a task over a 24 hour perdiod, and determines the maximum time it took to run it:

```dart
Duration max = monitor.history.getForTask('synch-data')
  .completed()
  .inTimePeriod(const Duration(hours: 24,))
  .maxTimeTaken();
```

Finally, to determine the percentage of times a task has failed over the last 24 hours:

```dart
double failRate = monitor.history.getForTask('synch-data')
  .inTimePeriod(const Duration(hours: 24,))
  .percentageFailed();
```

## Example

Here's an example that shows various areas of functionality:

```dart
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
        SynchCounts counts = update.data['counts'];
        print('Created ${counts.created} records, updated ${counts.updated} and deleted ${counts.deleted}');
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
```

## Cron Example

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

## Storing History

You'll likely want to store the monitor's history somewhere, but this library doesn't make any assumptions about your storage mechanism of choice.

You can create a JSON "snapshot" of the history at any time:

```dart
Map<String, dynamic> json = monitor.history.toJson();
```

A good time to do this is whenever a task is added to it:

```dart
monitor.executions.listen((_) {
  Map<String, dynamic> json = monitor.history.toJson();
  // do something with the resulting JSON, e.g. save to Hive
});
```

To restore it:

```dart
monitor.history.loadFromJson(json);
```

Alternatively, you could listen for new records and save them individually:

```dart
monitor.executions.listen((execution) {
  // do something with the resulting object, e.g. insert into an SQLite database
});
```

You can add an instance of `TaskExecution` later:

```dart
monitor.history.add(execution);
```

> The `TaskExecution` class can load from, and export to JSON 

To make this easier, each task has an auto-generated unique ID you could use as a primary key if you wish.

## Miscellany

In general, you'd probably want to create a single instance of the task monitor; there are various ways to do this, including using the [Get It](https://pub.dev/packages/get_it) package. That may not always be the case; if you have a bunch of discreet tasks &mdash; such as running the tasks that make up your app's initialization process &mdash; then you may want to create an instance in the context of that process.

There's a minor limitation when storing history, in that there's no reliable way to store exceptions; consider using the `message` field if you need more detail about why tasks failed historically.

Be careful when storing past task executions, as the time a task takes is stored in milliseconds; if you forget to mark a task as complete, or if you have extremely long-running tasks, then that number might get too big for, for example, storing in SQLite.

This package would work well with the [logging](https://pub.dev/packages/logging) package, e.g.:

```dart
logger = Logger('TaskMonitor');

TaskMonitor monitor = TaskMonitor();
Task task = monitor.create(id: 'synch-data');

monitor.updates.listen((update) => {
  if(update.status == TaskStatus.started) {
    logger.finer('${update.task.name} has started');
  } else if(update.status == TaskStatus.completed) {
    logger.fine('${update.task.name} ran in ${update.duration!.inMilliseconds}ms');
  } else if(update.status == TaskStatus.failed) {
    logger.severe('${update.task.name} failed!');
    yourCustomErrorHandler.log(
      id: update.task.id,
      error: update.error,
    );
  }
});
```

