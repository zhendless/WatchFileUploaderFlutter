import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';

class FolderSelector extends StatelessWidget {
  final String? currentPath;
  final Function(String) onFolderSelected;
  final bool isMonitoring;

  const FolderSelector({
    super.key,
    required this.currentPath,
    required this.onFolderSelected,
    this.isMonitoring = false,
  });

  Future<void> _selectFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      onFolderSelected(selectedDirectory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: AppTheme.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('监控文件夹', style: Theme.of(context).textTheme.titleMedium),
              if (isMonitoring) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '监控中',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMonitoring
                    ? AppTheme.successGreen.withOpacity(0.5)
                    : AppTheme.surfaceColor,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentPath != null ? Icons.folder : Icons.folder_open,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentPath ?? '未选择文件夹',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: currentPath != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isMonitoring ? null : () => _selectFolder(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('选择文件夹'),
            ),
          ),
        ],
      ),
    );
  }
}
