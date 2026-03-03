import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';

/// Shared loading widget with branding
class AppLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoadingWidget({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-page loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(color: Colors.black26, child: const AppLoadingWidget()),
      ],
    );
  }
}
