import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../models/search_result.dart';

enum SearchType { all, title, author }

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class BookApiService {
  static const _host = 'openlibrary.org';
  static const _fields =
      'key,title,author_name,first_publish_year,cover_i,isbn,subject,'
      'publisher,number_of_pages_median,language';

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw ApiException('Server error (${response.statusCode}). Please try again.');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request took too long. Please try again.');
    } catch (_) {
      throw ApiException('Could not load data. Check your internet connection.');
    }
  }
  Future<SearchResult> search(
    String query, {
    SearchType type = SearchType.all,
    int page = 1,
    int limit = 20,
    String? sort,
    String? language,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'fields': _fields,
    };
    switch (type) {
      case SearchType.all:
        params['q'] = query;
        break;
      case SearchType.title:
        params['title'] = query;
        break;
      case SearchType.author:
        params['author'] = query;
        break;
    }
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (language != null && language.isNotEmpty) params['language'] = language;

    final data = await _getJson(Uri.https(_host, '/search.json', params));
    final docs = (data['docs'] as List? ?? []);
    return SearchResult(
      books: docs
          .map((d) => Book.fromSearchJson(d as Map<String, dynamic>))
          .toList(),
      total: data['numFound'] as int? ?? 0,
    );
  }
  Future<SearchResult> getSubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    final slug = subject.trim().toLowerCase().replaceAll(' ', '_');
    final data = await _getJson(Uri.https(_host, '/subjects/$slug.json', {
      'limit': '$limit',
      'offset': '${(page - 1) * limit}',
    }));
    final works = (data['works'] as List? ?? []);
    return SearchResult(
      books: works
          .map((w) => Book.fromSubjectJson(w as Map<String, dynamic>))
          .toList(),
      total: data['work_count'] as int? ?? 0,
    );
  }
  Future<String?> getDescription(String workKey) async {
    final data = await _getJson(Uri.https(_host, '$workKey.json'));
    final d = data['description'];
    if (d is String) return d;
    if (d is Map && d['value'] != null) return d['value'].toString();
    return null;
  }
}