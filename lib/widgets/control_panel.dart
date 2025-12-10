import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';

class ControlPanel extends StatelessWidget {
  final bool isMonitoring;
  final bool canStart;
  final VoidCallback onToggleMonitoring;
  final Function(String) onManualUpload;

  const ControlPanel({
    super.key,
    required this.isMonitoring,
    required this.canStart,
    required this.onToggleMonitoring,
    required this.onManualUpload,
  });

  Future<void> _selectFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      onManualUpload(result.files.single.path!);
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
          Text('控制面板', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    onPressed: canStart ? onToggleMonitoring : null,
                    icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                    label: Text(isMonitoring ? '停止监控' : '开始监控'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMonitoring
                          ? AppTheme.errorRed
                          : AppTheme.primaryCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectFile(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('手动上传'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
            ],
          ),
          if (!canStart && !isMonitoring) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningOrange.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请先配置监控文件夹和上传地址',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.warningOrange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
