class TaskService {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name cannot be empty';
    }
    return null;
  }
}
