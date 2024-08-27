import 'package:collection/collection.dart';

import 'task.dart';
import 'task_execution.dart';
import 'task_status.dart';
import 'dart:collection';

class TasksList extends ListBase<TaskExecution> {

  /** 
  TasksList completed() {
    return TasksList.from(TasksList.where((task) => task.isCompleted));
  }
  **/
  List<TaskExecution> innerList = [];

  @override
  int get length => innerList.length;

  @override
  set length(int length) {
    innerList.length = length;
  }

  @override
  void operator[]=(int index, TaskExecution value) {
    innerList[index] = value;
  }

  @override
  TaskExecution operator [](int index) => innerList[index];

  @override
  void add(TaskExecution element) => innerList.add(element);

  @override
  void addAll(Iterable<TaskExecution> iterable) => innerList.addAll(iterable);

  TasksList completed() {
    return TasksList()..addAll(innerList.where((task) => task.isCompleted));
  }

  TasksList failed() {
    return TasksList()..addAll(innerList.where((task) => task.isFailed));
  }

  TasksList completedOrFailed() {
    return TasksList()..addAll(innerList.where((task) => task.isCompletedOrFailed));
  }

  TasksList since(DateTime timestamp) {
    return TasksList()..addAll(innerList.where((task) => task.startedAt.isAfter(timestamp)));
  }

  TasksList inTimePeriod(Duration duration) {
    return TasksList()..addAll(innerList.where(
      (task) => DateTime.now().difference(task.startedAt).inMilliseconds <= duration.inMilliseconds));
  }

  TasksList failedSince(DateTime timestamp) {
    return TasksList()..addAll(failed().where((task) => task.startedAt.isAfter(timestamp)));
  }

  TasksList failedInTimePeriod(Duration duration) {
    return TasksList()..addAll(failed().where(
      (task) => DateTime.now().difference(task.startedAt).inMilliseconds <= duration.inMilliseconds));
  }

  double percentageFailed() {
    if(innerList.isEmpty) return 0;
    int numFailed = failed().length;
    return numFailed / length * 100;
  }

  double percentageCompleted() {
    if(innerList.isEmpty) return 0;
    int numCompleted = completed().length;
    return numCompleted / length * 100;
  }

  Duration? maxTimeTaken() {
    TasksList tasks = completedOrFailed();
    if(tasks.isEmpty) {
      return null;
    }
    return Duration(milliseconds: tasks.map((task) => task.duration!.inMilliseconds).max);
  }

  Duration averageTimeTaken() {
    TasksList tasks = completedOrFailed();
    if(tasks.isEmpty) {
      return Duration.zero;
    }
    int total = tasks.map((task) => task.duration!.inMilliseconds).sum;
    return Duration(milliseconds: total ~/ tasks.length);
  }

}