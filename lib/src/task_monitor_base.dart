import 'task.dart';
import 'task_status.dart';
import 'update.dart';
import 'task_execution.dart';
import 'history.dart';
import 'errors/errors.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:math';

class TaskMonitor {

  final List<Task> _tasks;
  final StreamController<Update> _controller;
  final Map<String, Stopwatch> _timers;
  final History history;
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
    history = History(enabled: historyEnabled, limit: historyLimit,);

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

  Task create({required String id, String? name, List<String>? tags,}) {
    if(getTask(id) != null) {
      throw DuplicateTaskId();
    }
    Task task = Task(
      id: id, 
      name: name,
      tags: tags,
      monitor: this,
      status: TaskStatus.pending,
    );
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

  Future<Task> run(
    Task task, 
    Function callback,
    {
      String? startedMessage,
      String? completedMessage,
      String? failedMessage,
    }
  ) async {
    task.start(message: startedMessage,);
    try {
      await callback();
      task.complete(message: completedMessage,);
      return task;
    } on Exception catch (e) {
      task.fail(error: e, message: failedMessage,);
      return task;
    }
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
    if(!_timers[task.id]!.isRunning) {
      return null;
    }
    return _timers[task.id]!.elapsed;
  }

  Duration getTotalElapsed() {
    return Duration(
      milliseconds: _timers.values
        .map((timer) => timer.elapsedMilliseconds).toList().sum,
      );
  }

  /// Note that this is for internal use; the monitor spawns tasks, and they
  /// communicate back via this method. This just means you can call methods like
  /// complete() on a task, rather than having to go through here.
  void notify({
    required Task task, 
    required TaskStatus status,
    String? message,
    Exception? error,
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
        history.add(TaskExecution(taskId: task.id, status: TaskStatus.started,));
      }
    }
    if(status == TaskStatus.completed || status == TaskStatus.failed) {
      _timers[task.id]!.stop();
      update.duration = _timers[task.id]!.elapsed;
      history.updateLast(
        TaskExecution(
          taskId: task.id, 
          status: status,
          duration: _timers[task.id]!.elapsed,
          message: message,
          error: error,
        )
      );      
    }    
    _controller.add(update);
  }

  void pause(Task task) {
    _timers[task.id]!.stop();
  }

  void resume(Task task) {
    _timers[task.id]!.start();
  }

  String uniqueId({String prefix = 'task'}) {
    List<String> existing = taskIds.where((id) => id.startsWith(prefix)).toList();
    final r = Random();
    String id;
    do {
      id = '$prefix-${r.nextInt(10000000)}';
    } while(existing.contains(id));
    return id;
  }

  List<String> get taskIds {
    return _tasks.map((task) => task.id).toList();
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

  List<Task> taggedWith(String tag) {
    return all.where((task) => task.hasTag(tag)).toList();
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

  void dispose() {
    _controller.close();
    for(String taskId in _timers.keys) {
      if(_timers[taskId] != null) 
      {
        _timers[taskId]!.stop();
      }
    }
  }

}