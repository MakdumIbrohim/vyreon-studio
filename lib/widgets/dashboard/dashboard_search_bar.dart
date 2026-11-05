import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DashboardSearchBar extends StatelessWidget {
  final int projectCount;
  final ValueChanged<String> onSearchChanged;

  const DashboardSearchBar({
    super.key,
    required this.projectCount,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Text(
            'MY PROJECTS ($projectCount)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
