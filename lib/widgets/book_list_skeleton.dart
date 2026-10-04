import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
class BookListSkeleton extends StatelessWidget {
  final int count;
  const BookListSkeleton({super.key, this.count = 6});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: dark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        itemCount: count, itemBuilder: (context, i) => _placeholderCard(),
      ),
    );
  }

  Widget _bar(double width, double height) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4),),
    );
  }

  Widget _placeholderCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,height: 100,decoration: BoxDecoration(
                color: Colors.white,borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(double.infinity, 16),
                  const SizedBox(height: 10),
                  _bar(140, 12),
                  const SizedBox(height: 10),
                   _bar(100, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
