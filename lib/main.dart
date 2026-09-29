import 'package:flutter/material.dart';
import 'services/book_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final result = await BookApiService().search('harry potter');
  debugPrint('Found ${result.total} books');
  debugPrint('First: ${result.books.first.title} by ${result.books.first.authorsText}');
  debugPrint('Cover: ${result.books.first.coverUrl()}');
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('API test')))));
}