import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UploadUrlField extends StatefulWidget {
  final String? currentUrl;
  final Function(String) onUrlSaved;
  final bool isMonitoring;

  const UploadUrlField({
    super.key,
    required this.currentUrl,
    required this.onUrlSaved,
    this.isMonitoring = false,
  });

  @override
  State<UploadUrlField> createState() => _UploadUrlFieldState();
}

class _UploadUrlFieldState extends State<UploadUrlField> {
  late TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _saveUrl() {
    final url = _controller.text.trim();
    final isValid = _validateUrl(url);

    setState(() {
      _isValid = isValid;
    });

    if (isValid) {
      widget.onUrlSaved(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('上传地址已保存'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                Icons.cloud_upload_outlined,
                color: AppTheme.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('上传地址', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !widget.isMonitoring,
            decoration: InputDecoration(
              hintText: 'https://example.com/api/upload',
              prefixIcon: const Icon(Icons.link),
              errorText: !_isValid ? '请输入有效的URL地址' : null,
              suffixIcon: !widget.isMonitoring
                  ? IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveUrl,
                      tooltip: '保存',
                    )
                  : null,
            ),
            onSubmitted: (_) => _saveUrl(),
          ),
          if (!_isValid) ...[
            const SizedBox(height: 8),
            Text(
              'URL必须以 http:// 或 https:// 开头',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
