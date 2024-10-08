import 'task_status.dart';
import 'mixins/has_status.dart';
import 'utils/id_generator.dart';

class TaskExecution with HasStatus {
  final String id;
  final String taskId;  
  final DateTime startedAt;
  TaskStatus _status;
  Duration? duration;
  String? message;
  Exception? error;
  String? errorType;

  TaskExecution({
    String? id,
    required this.taskId,
    required TaskStatus status,
    DateTime? startedAt,
    this.duration,
    this.message,
    this.error,
  }): 
    id = id ?? IdGenerator.generate(),
    _status = status, startedAt = startedAt ?? DateTime.now();

  TaskExecution.fromJson(Map<String, dynamic> data):
    id = data['id'],
    taskId = data['taskId'],
    _status = TaskStatus.values.where((status) => status.name == data['status']).first,
    startedAt = DateTime.parse(data['startedAt']),
    duration = data['duration'] != null ? Duration(milliseconds: data['duration']) : null,
    message = data['message'],
    errorType = data['error'];

  DateTime? get completedAt {
    if(duration == null) {
      return null;
    }
    return startedAt.add(duration!);
  }

  @override
  TaskStatus get status {
    return _status;
  }

  set status(TaskStatus status) {
    _status = status;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'status': _status.name,
      'startedAt': startedAt.toIso8601String(),
      'duration': duration?.inMilliseconds, 
      'message': message,
      'error': error?.toString(),
    };
  }
}