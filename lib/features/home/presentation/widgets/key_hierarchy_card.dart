import 'package:flutter/material.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';

class KeyHierarchyCard extends StatelessWidget {
  final int doctorCount;

  const KeyHierarchyCard({
    super.key,
    this.doctorCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Key Hierarchy",
                style: AppTextStyle.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
              Text(
                "View All",
                style: AppTextStyle.labelMedium.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.large),
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.badge,
                      size: 32,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.small),
                Text(
                  "Master Key",
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: context.colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    "Patient Owner",
                    style: AppTextStyle.labelSmall.copyWith(
                      color: context.colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.medium),
          Center(
            child: Container(
              width: 2,
              height: 20,
              color: context.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: Insets.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubKey(
                  context, "Doctor", Icons.person, doctorCount, Colors.blue),
              _buildSubKey(
                  context, "Hospital", Icons.local_hospital, 2, Colors.orange),
              _buildSubKey(context, "Lab", Icons.science, 1, Colors.purple),
              _buildSubKey(context, "Emergency", Icons.warning, 1, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubKey(
    BuildContext context,
    String label,
    IconData icon,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyle.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onSurface,
          ),
        ),
        Text(
          "$count keys",
          style: AppTextStyle.labelSmall.copyWith(
            fontSize: 10,
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
