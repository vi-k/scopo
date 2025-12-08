extension StringTrim on String {
  String trimIndent() {
    final lines = split('\n');
    var minIndent = -1;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final indent = line.length - line.trimLeft().length;
      if (minIndent == -1 || indent < minIndent) {
        minIndent = indent;
      }
    }

    if (minIndent == -1) minIndent = 0;

    final resultLines = lines.map((line) {
      if (line.length >= minIndent) {
        return line.substring(minIndent);
      }
      return line;
    }).toList();

    if (resultLines.isNotEmpty && resultLines.first.trim().isEmpty) {
      resultLines.removeAt(0);
    }
    if (resultLines.isNotEmpty && resultLines.last.trim().isEmpty) {
      resultLines.removeLast();
    }

    return resultLines.join('\n');
  }
}
