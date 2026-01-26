String typeToShortString(Type type) {
  final str = type.toString();
  final index = str.indexOf('<');
  return index < 0 ? str : str.substring(0, index);
}
