String normalizeCatalogText(String value) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ú': 'u',
    'Ü': 'u',
    'Ñ': 'n',
  };
  final buffer = StringBuffer();
  var previousWasSpace = false;
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    final replacement = replacements[character] ?? character.toLowerCase();
    final isWord = RegExp(r'[a-z0-9]').hasMatch(replacement);
    if (isWord) {
      buffer.write(replacement);
      previousWasSpace = false;
    } else if (!previousWasSpace && buffer.isNotEmpty) {
      buffer.write(' ');
      previousWasSpace = true;
    }
  }
  return buffer.toString().trim();
}
