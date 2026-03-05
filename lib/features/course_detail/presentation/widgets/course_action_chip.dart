import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Quick-action chip used in course detail page (quizzes, assignments, etc.)
class CourseActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const CourseActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
