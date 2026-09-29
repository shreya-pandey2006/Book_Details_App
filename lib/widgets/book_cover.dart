import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.url,
    this.width = 70,
    this.height = 100,
  });

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    return Container(
      width: width, height: height, color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        loading ? Icons.hourglass_empty : Icons.menu_book, color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? _placeholder(context) : CachedNetworkImage(
              imageUrl: url!, width: width, height: height, fit: BoxFit.cover, placeholder: (c, _) => _placeholder(c, loading: true),
              errorWidget: (c, _, __) => _placeholder(c),
            ),
    );
  }
}