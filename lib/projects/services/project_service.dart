class ProjectService {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name cannot be empty';
    }
    return null;
  }

  static bool isFormValid(String name) {
    return name.trim().isNotEmpty;
  }
}
