import 'task.dart';
import 'task_status.dart';

class Update {

  final Task task;
  final TaskStatus status;
  final DateTime timestamp;
  Duration? duration;
  String? message;
  Error? error;

  Update({
    required this.task,
    required this.status,
    this.duration,
    this.message,
    this.error,
  }): timestamp = DateTime.now();

  Update.started({
    required this.task,
    this.message,
    this.error,
  }): status = TaskStatus.started, timestamp = DateTime.now();

  Update.completed({
    required this.task,
    required this.duration,
    this.message,
    this.error,
  }): status = TaskStatus.completed, timestamp = DateTime.now();


  bool get hasMessage {
    return message != null;
  }

  bool get hasError {
    return error != null;
  }

}