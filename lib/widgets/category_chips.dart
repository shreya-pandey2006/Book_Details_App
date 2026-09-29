import 'package:flutter/material.dart';
import '../screens/subject_screen.dart';

/// Popular categories shown on the home screen before the first search.
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  static const categories = [
    'Fiction',
    'Fantasy',
    'Science',
    'History',
    'Romance',
    'Mystery',
    'Biography',
    'Children',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Text('Browse by category',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categories
                .map((c) => ActionChip(
                      label: Text(c),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SubjectScreen(subject: c)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}