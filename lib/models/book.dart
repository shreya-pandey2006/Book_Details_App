List<String> _stringList(dynamic value, {int max = 10}) {
  if (value is List) {
    return value.map((e) => e.toString()).take(max).toList();
  }
  return [];
}

class Book {
  final String key; // e.g. /works/OL45804W
  final String title;
  final List<String> authors;
  final int? firstPublishYear;
  final int? coverId;
  final String? isbn;
  final List<String> subjects;
  final List<String> publishers;
  final int? pages;
  final List<String> languages;

  Book({
    required this.key,
    required this.title,
    this.authors = const [],
    this.firstPublishYear,
    this.coverId,
    this.isbn,
    this.subjects = const [],
    this.publishers = const [],
    this.pages,
    this.languages = const [],
  });

  /// Build a Book from one item of search.json -> "docs"
  factory Book.fromSearchJson(Map<String, dynamic> json) {
    final isbns = _stringList(json['isbn'], max: 1);
    return Book(
      key: json['key'] ?? '',
      title: json['title'] ?? 'Untitled',
      authors: _stringList(json['author_name']),
      firstPublishYear: json['first_publish_year'] as int?,
      coverId: json['cover_i'] as int?,
      isbn: isbns.isEmpty ? null : isbns.first,
      subjects: _stringList(json['subject']),
      publishers: _stringList(json['publisher'], max: 5),
      pages: json['number_of_pages_median'] as int?,
      languages: _stringList(json['language'], max: 5),
    );
  }

  /// Build a Book from one item of /subjects/xxx.json -> "works"
  factory Book.fromSubjectJson(Map<String, dynamic> json) {
    final authorList = json['authors'];
    return Book(
      key: json['key'] ?? '',
      title: json['title'] ?? 'Untitled',
      authors: authorList is List
          ? authorList.map((a) => (a['name'] ?? '').toString()).toList()
          : [],
      firstPublishYear: json['first_publish_year'] as int?,
      coverId: json['cover_id'] as int?,
      subjects: _stringList(json['subject']),
    );
  }

  /// Cover image address. size: 'S', 'M' or 'L'. Returns null if no cover.
  String? coverUrl({String size = 'L'}) {
    if (coverId != null) {
      return 'https://covers.openlibrary.org/b/id/$coverId-$size.jpg';
    }
    if (isbn != null) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg?default=false';
    }
    return null;
  }

  String get authorsText =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');
}