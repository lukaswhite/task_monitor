import 'task.dart';
import 'task_status.dart';
import 'mixins/has_status.dart';

class Update with HasStatus {

  final Task task;
  final TaskStatus _status;
  final DateTime timestamp;
  Duration? duration;
  String? message;
  Exception? error;
  Map<String, dynamic> data;

  Update({
    required this.task,
    required TaskStatus status,
    this.duration,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): _status = status, timestamp = DateTime.now(), data = data ?? {};

  Update.started({
    required this.task,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): _status = TaskStatus.started, 
    timestamp = DateTime.now(),
    data = data ?? {};

  Update.completed({
    required this.task,
    required this.duration,
    this.message,
    Map<String, dynamic>? data,
  }): _status = TaskStatus.completed, timestamp = DateTime.now(), data = data ?? {};

  Update.failed({
    required this.task,
    required this.duration,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): _status = TaskStatus.failed, timestamp = DateTime.now(), data = data ?? {};

  bool get hasMessage {
    return message != null;
  }

  bool get hasError {
    return error != null;
  }

  bool get hasData {
    return data.keys.isNotEmpty;
  }

  T? getData<T>(String name) {
    if(!data.containsKey(name)) {
      return null;
    }
    return data[name] as T;
  }

  @override
  TaskStatus get status {
    return _status;
  }

  @override
  String toString() {
    return '${task.name}: ${status.name}';
  }
}