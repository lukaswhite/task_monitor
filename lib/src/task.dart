import 'task_status.dart';
import 'task_monitor_base.dart';
import 'errors/errors.dart';
import 'mixins/has_status.dart';

class Task with HasStatus {
  
  final String id;
  final String name;
  final TaskMonitor _monitor;
  final bool allowConcurrent;
  TaskStatus _status;
  Map<String, dynamic> data = {};

  /// Note that you shouldn't instantiate a task directly; let the monitor do it.
  /// That way, the task has a line of communication back to the monitor, which
  /// is integral to how the whole system works.
  Task({
    required this.id, 
    required TaskStatus status,
    required TaskMonitor monitor,
    String? name,
    this.allowConcurrent = false,
  }): _status = status, _monitor = monitor, name = name ?? id;
  
  Task.start({
    required this.id,
    required TaskMonitor monitor,
    String? name,
    this.allowConcurrent = false,
  }): _monitor = monitor, _status = TaskStatus.started, name = name ?? id;

  void start({String? message}) {
    if(!canStart) {
      throw TaskCannotStart();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.started,
      message: message,
    );
    _status = TaskStatus.started;
  }

  void complete({
    String? message,
    Map<String, dynamic>? data,
  }) {
    if(status != TaskStatus.started) {
      throw TaskNotStarted();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.completed,
      message: message,
      data: data,
    );
    _status = TaskStatus.completed;
  }

  void fail({String? message, Exception? error,}) {
    if(status != TaskStatus.started) {
      throw TaskNotStarted();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.failed,
      message: message,
      error: error,
    );
    _status = TaskStatus.failed;
  }

  bool get canStart {
    return allowConcurrent || isPending || isCompleted || isFailed;
  }

  @override
  TaskStatus get status {
    return _status;
  }

  @override
  String toString() {
    return '$id: ${status.name}';
  }
}