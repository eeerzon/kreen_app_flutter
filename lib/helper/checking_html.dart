
  bool isHtmlEmpty(String html) {
    final text = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', '')
        .trim();

    return text.isEmpty;
  }