class ProjectService {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name cannot be empty';
    }
    return null;
  }

  static bool isFormValid(
    String name,
    String current,
    String endGoal,
    String unit,
  ) {
    return name.trim().isNotEmpty &&
        current.trim().isNotEmpty &&
        endGoal.trim().isNotEmpty &&
        unit.trim().isNotEmpty &&
        int.tryParse(current) != null &&
        int.tryParse(endGoal) != null;
  }
}
