extension StringExtension on String {
  T? tryParse<T>() {
    if (T == String) {
      return this as T;
    } else if (T == int) {
      return int.tryParse(this) as T?;
    } else if (T == double) {
      return double.tryParse(this) as T?;
    } else if (T == bool) {
      return (toLowerCase() == 'true') as T;
    }
    return null;
  }
}
