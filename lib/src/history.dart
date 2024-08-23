import 'dart:async';

import 'package:task_monitor/task_monitor.dart';

class History {

  final Map<String, List<TaskExecution>> _entries;
  bool enabled;
  int? limit;
  final StreamController<TaskExecution> _controller;
  final List<String> _ignoredTasks = [];

  History({
    this.limit,
    this.enabled = true,
  }): _entries = {}, 
    _controller = StreamController<TaskExecution>.broadcast();

  Stream<TaskExecution> get executions {
    return _controller.stream;
  }

  List<TaskExecution> getForTask(String taskId) {
    return getOrCreateByTaskId(taskId);
  }

  void add(TaskExecution execution) {
    if(isDisabled) return;
    if(shouldIgnore(execution.taskId)) return; 
    getOrCreateByTaskId(execution.taskId).add(execution);
    if(limit != null && getOrCreateByTaskId(execution.taskId).length > limit!) {
      getOrCreateByTaskId(execution.taskId).removeRange(0, getOrCreateByTaskId(execution.taskId).length - limit!);
    }
  }
 
  void updateLast(TaskExecution execution) {
    if(isDisabled) return;
    if(shouldIgnore(execution.taskId)) return;
    TaskExecution? last = lastStarted(execution.taskId);
    if(last != null) {
      _entries[execution.taskId]![_entries[execution.taskId]!.length-1] = execution;
      _controller.add(execution);
    }
  }
 
  TaskExecution? last(String taskId) {
    return getOrCreateByTaskId(taskId).lastOrNull;
  }

  TaskExecution? lastStarted(String taskId) {
    return lastWithStatus(taskId, TaskStatus.started);
  }

  TaskExecution? lastWithStatus(String taskId, TaskStatus status) {
    return getOrCreateByTaskId(taskId).where((task) => task.status == status).lastOrNull;
  }

  TaskExecution? lastCompleted(String taskId) {
    return lastWithStatus(taskId, TaskStatus.completed);
  }

  DateTime? lastCompletedAt(String taskId) {
    TaskExecution? task = lastCompleted(taskId);
    return task?.completedAt!;
  }

  Duration? getTimeSinceLastCompleted(String taskId) {
    TaskExecution? last = lastCompleted(taskId);
    if(last == null) {
      return null;
    }
    return DateTime.now().difference(last.completedAt!);
  }

  DateTime? lastRun(String taskId) {
    TaskExecution? task = last(taskId);
    if(task == null) {
      return null;
    }
    return task.startedAt;
  }

  void enable() {
    enabled = true;
  }

  void disable() {
    enabled = false;
  }

  void clear(String taskId) {
    getOrCreateByTaskId(taskId).clear();
  }

  void clearAll() {
    for(String taskId in _entries.keys) {
      _entries[taskId]!.clear();
    }
  }

  void clearTo(String taskId, Duration duration) {
    _entries[taskId] = getOrCreateByTaskId(taskId)
      .where((task) => DateTime.now().difference(task.startedAt).inMilliseconds < duration.inMilliseconds)
      .toList();
  }

  void clearAllTo(Duration duration) {
    for(String taskId in _entries.keys) {
      clearTo(taskId, duration);
    }
  }

  List<TaskExecution>? getByTaskId(String taskId) {
    return _entries[taskId];
  }

  List<TaskExecution> getOrCreateByTaskId(String taskId) {
    if(_entries.keys.contains(taskId)) {
      return _entries[taskId]!;
    }
    _entries[taskId] = [];
    return _entries[taskId]!;
  }

  bool get isEnabled {
    return enabled;
  }

  bool get isDisabled {
    return !isEnabled;
  }

  void ignore(String taskId) {
    if(!_ignoredTasks.contains(taskId)) {
      _ignoredTasks.add(taskId);
    }
  }

  bool shouldIgnore(String taskId) {
    return _ignoredTasks.contains(taskId);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for(String taskId in _entries.keys) {
      json[taskId] = _entries[taskId]!.map((task) => task.toJson());
    }
    return json;
  }

  void loadFromJson(Map<String, dynamic> json) {
    for(String taskId in json.keys) {
      _entries[taskId] = json[taskId].map((item) => TaskExecution.fromJson(item)).cast<TaskExecution>().toList();
    }
  }

  void dispose() {
    _controller.close();
  }

}