import '../task_status.dart';

mixin HasStatus {
  
  TaskStatus get status;

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

}