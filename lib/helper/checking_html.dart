
  bool isHtmlEmpty(String? html) {
    if (html == null || html.isEmpty) return true;
    
    final text = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', '')
        .trim();

    return text.isEmpty;
  }