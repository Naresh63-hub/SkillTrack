class Validators {
  static String? requiredField(String? value,
      [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? progress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Progress is required';
    }
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0 || parsed > 100) {
      return 'Progress must be between 0 and 100';
    }
    return null;
  }

  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid URL (starting with http:// or https://)';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? positiveInteger(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }
}
