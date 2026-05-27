import 'package:flutter/material.dart';
import '../models/weight_database.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final String category;
  const CategoryChip({super.key, required this.label, required this.category});

  @override
  Widget build(BuildContext context) {
    final count = WeightDatabase.getByCategory(category).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
