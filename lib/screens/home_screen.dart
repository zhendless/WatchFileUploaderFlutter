import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/upload_log.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_card.dart';
import '../widgets/folder_selector.dart';
import '../widgets/upload_url_field.dart';
import '../widgets/control_panel.dart';
import '../widgets/log_entry_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UploadStatus? _filterStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (!appState.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.darkBackground,
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryCyan,
                              AppTheme.primaryPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('文件上传监控'),
                    ],
                  ),
                  centerTitle: false,
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: '今日上传',
                            value: '${appState.uploadsToday}',
                            icon: Icons.today,
                            gradientColors: const [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: '总上传数',
                            value: '${appState.totalUploads}',
                            icon: Icons.cloud_done,
                            gradientColors: const [
                              AppTheme.primaryCyan,
                              Color(0xFF0099CC),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: '成功率',
                            value:
                                '${appState.successRate.toStringAsFixed(1)}%',
                            icon: Icons.check_circle,
                            gradientColors: const [
                              AppTheme.successGreen,
                              Color(0xFF00CC66),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Configuration Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FolderSelector(
                            currentPath: appState.settings.monitoredFolderPath,
                            isMonitoring: appState.isMonitoring,
                            onFolderSelected: (path) {
                              appState.updateSettings(
                                appState.settings.copyWith(
                                  monitoredFolderPath: path,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: UploadUrlField(
                            currentUrl: appState.settings.uploadUrl,
                            isMonitoring: appState.isMonitoring,
                            onUrlSaved: (url) {
                              appState.updateSettings(
                                appState.settings.copyWith(uploadUrl: url),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Control Panel
                    ControlPanel(
                      isMonitoring: appState.isMonitoring,
                      canStart: appState.settings.isValid,
                      onToggleMonitoring: () async {
                        if (appState.isMonitoring) {
                          await appState.stopMonitoring();
                        } else {
                          final success = await appState.startMonitoring();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('启动监控失败，请检查配置'),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                          }
                        }
                      },
                      onManualUpload: (filePath) async {
                        final success = await appState.uploadFileManually(
                          filePath,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? '文件已添加到上传队列' : '上传失败'),
                              backgroundColor: success
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Upload Logs Section
                    Container(
                      decoration: AppTheme.cardGradient,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '上传日志',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Row(
                                children: [
                                  _buildFilterChip('全部', null),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('成功', UploadStatus.success),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('失败', UploadStatus.failure),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Logs List
                          if (appState.logs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无上传记录',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 400,
                              child: ListView.builder(
                                itemCount: appState
                                    .getLogsByStatus(_filterStatus)
                                    .length,
                                itemBuilder: (context, index) {
                                  final log = appState.getLogsByStatus(
                                    _filterStatus,
                                  )[index];
                                  return LogEntryCard(log: log);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, UploadStatus? status) {
    final isSelected = _filterStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryCyan.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCyan : AppTheme.textSecondary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryCyan : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
