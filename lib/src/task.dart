import 'task_status.dart';
import 'task_monitor_base.dart';
import 'errors/errors.dart';

class Task {
  
  final String id;
  final String name;
  final TaskMonitor _monitor;
  final bool allowConcurrent;
  TaskStatus status;
  Map<String, dynamic> data = {};

  Task({
    required this.id, 
    required this.status,
    required TaskMonitor monitor,
    String? name,
    this.allowConcurrent = false,
  }): _monitor = monitor, name = name ?? id;
  
  Task.start({
    required this.id,
    required TaskMonitor monitor,
    String? name,
    this.allowConcurrent = false,
  }): _monitor = monitor, status = TaskStatus.started, name = name ?? id;

  void start({String? message}) {
    if(!canStart) {
      throw TaskCannotStart();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.started,
      message: message,
    );
    status = TaskStatus.started;
  }

  void complete({String? message,}) {
    if(status != TaskStatus.started) {
      throw TaskNotStarted();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.completed,
      message: message,
    );
    status = TaskStatus.completed;
  }

  void fail({String? message, Error? error,}) {
    if(status != TaskStatus.started) {
      throw TaskNotStarted();
    }
    _monitor.notify(
      task: this, 
      status: TaskStatus.failed,
      message: message,
      error: error,
    );
    status = TaskStatus.failed;
  }

  bool get canStart {
    return allowConcurrent || isPending || isCompleted || isFailed;
  }

  bool get isStarted {
    return status == TaskStatus.started;
  }

  bool get isRunning {
    return isStarted;
  }

  bool get isPending {
    return status == TaskStatus.pending;
  }

  bool get isCompleted {
    return status == TaskStatus.completed;
  }

  bool get isFailed {
    return status == TaskStatus.failed;
  }

  bool get isCompletedOrFailed {
    return isCompleted || isFailed;
  }

  @override
  String toString() {
    return '$id: ${status.name}';
  }
}