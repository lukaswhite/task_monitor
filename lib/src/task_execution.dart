import 'task_status.dart';

class TaskExecution {
  final String taskId;  
  final DateTime startedAt;
  TaskStatus status;
  Duration? duration;
  String? message;
  Error? error;

  TaskExecution({
    required this.taskId,
    required this.status,
    this.duration,
    this.message,
    this.error,
  }): startedAt = DateTime.now();

  DateTime? get completedAt {
    if(duration == null) {
      return null;
    }
    return startedAt.add(duration!);
  }
}