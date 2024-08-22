import 'task.dart';
import 'task_status.dart';

class Update {

  final Task task;
  final TaskStatus status;
  final DateTime timestamp;
  Duration? duration;
  String? message;
  Error? error;
  Map<String, dynamic> data;

  Update({
    required this.task,
    required this.status,
    this.duration,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): timestamp = DateTime.now(), data = data ?? {};

  Update.started({
    required this.task,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): status = TaskStatus.started, 
    timestamp = DateTime.now(),
    data = data ?? {};

  Update.completed({
    required this.task,
    required this.duration,
    this.message,
    this.error,
    Map<String, dynamic>? data,
  }): status = TaskStatus.completed, timestamp = DateTime.now(), data = data ?? {};

  bool get hasMessage {
    return message != null;
  }

  bool get hasError {
    return error != null;
  }

  bool get hasData {
    return data.keys.isNotEmpty;
  }

}