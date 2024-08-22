import 'task.dart';
import 'task_status.dart';
import 'update.dart';
import 'task_execution.dart';
import 'errors/errors.dart';
import 'package:collection/collection.dart';
import 'dart:async';

class TaskMonitor {

  final List<Task> _tasks;
  final StreamController<Update> _controller;
  final Map<String, Stopwatch> _timers;
  final Map<String, List<TaskExecution>> _history;
  bool historyEnabled;
  int? historyLimit;
  bool isLogging = false;

  TaskMonitor({
    this.historyEnabled = true,
    this.historyLimit,
  }): 
    _tasks = [], 
    _controller = StreamController<Update>.broadcast(),
    _timers = {},
    _history = {};

  Stream<Update> get updates {
    return _controller.stream;
  }

  Stream<Update> get startedUpdates {
    return _controller.stream.where((update) => update.status == TaskStatus.started);
  }

  Stream<Update> get completedUpdates {
    return _controller.stream.where((update) => update.status == TaskStatus.completed);
  }

  Stream<Update> get failedUpdates {
    return _controller.stream.where((update) => update.status == TaskStatus.failed);
  }

  Task create({required String id, String? name,}) {
    if(getTask(id) != null) {
      throw DuplicateTaskId();
    }
    Task task = Task(
      id: id, 
      name: name,
      monitor: this,
      status: TaskStatus.pending,
    );
    _history[task.id] = [];
    _tasks.add(task); 
    return task;
  }

  Task getOrCreate({required String id, String? name}) {
    return getTask(id) ?? create(id: id, name: name);
  }

  Task start({required String id, String? name,}) {
    return create(
      id: id,
      name: name,
    )..start();
  }

  Task? getTask(String id) {
    return _tasks.firstWhereOrNull(
      (task) => task.id == id,
    );
  }

  Duration? getElapsed(Task task) {
    if(!_timers.keys.contains(task.id)) {
      return null;
    }
    if(_timers[task.id]!.isRunning) {

    }
    return _timers[task.id]!.elapsed;
  }

  Duration getTotalElapsed() {
    return Duration(
      milliseconds: _timers.values
        .map((timer) => timer.elapsedMilliseconds).toList().sum,
      );
  }

  void notify({
    required Task task, 
    required TaskStatus status,
    String? message,
    Error? error,
    Map<String, dynamic>? data,
  }) {
    Update update = Update(
      task: task, 
      status: status,
      message: message,
      error: error,
      data: data,
    );
    if(status == TaskStatus.started) {
      _timers[task.id] = Stopwatch()..start();
      if(historyEnabled) {
        _history[task.id]!.add(TaskExecution(taskId: task.id, status: TaskStatus.started,));
        if(historyLimit != null && _history[task.id]!.length > historyLimit!) {
          _history[task.id]!.removeRange(0, _history[task.id]!.length - historyLimit!);
        }
      }
    }
    if(status == TaskStatus.completed || status == TaskStatus.failed) {
      _timers[task.id]!.stop();
      update.duration = _timers[task.id]!.elapsed;
      //print( _history[task.id]!.last.status);
      if(historyEnabled && _history[task.id] != null && _history[task.id]!.isNotEmpty && _history[task.id]!.last.status == TaskStatus.started) {
        TaskExecution execution = _history[task.id]!.last;
        execution.status = status;
        execution.duration = _timers[task.id]!.elapsed;
        execution.message = message;
        if(error != null && status == TaskStatus.failed) {
          execution.error = error;
        }
        _history[task.id]![_history[task.id]!.length-1] = execution;
      }
    }    
    _controller.add(update);
  }

  void pause(Task task) {
    _timers[task.id]!.stop();
  }

  void resume(Task task) {
    _timers[task.id]!.start();
  }

  List<Task> get all {
    return _tasks;
  }

  List<Task> get pending {
    return _tasks.where((task) => task.isPending).toList();
  }

  List<Task> get running {
    return _tasks.where((task) => task.isStarted).toList();
  }

  List<Task> get completed {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  int get totalTasks {
    return _tasks.length;
  }

  int get numCompleted {
    return completed.length;
  }

  bool get isAllCompleted {
    return numCompleted == totalTasks;
  }

  bool get isNotAllCompleted {
    return !isAllCompleted;
  }

  int get numRunning {
    return running.length;
  }

  List<TaskExecution> getHistory(String taskId) {
    if(getTask(taskId) == null) {
      throw TaskNotFound();
    }
    return _history[taskId]!;
  }

  void clearHistory(String taskId) {
    if(getTask(taskId) == null) {
      throw TaskNotFound();
    }
    _history[taskId]!.clear();
  }

  void clearAllHistory() {
    for(String taskId in _history.keys) {
      clearHistory(taskId);
    }
  }

}