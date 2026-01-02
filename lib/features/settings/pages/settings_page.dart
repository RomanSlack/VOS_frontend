import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/bloc/settings_bloc.dart';
import 'package:vos_app/features/settings/bloc/settings_event.dart';
import 'package:vos_app/features/settings/bloc/settings_state.dart';
import 'package:vos_app/features/settings/data/voice_options.dart';
import 'package:vos_app/features/settings/widgets/voice_selector.dart';
import 'package:vos_app/features/settings/widgets/system_prompts/system_prompts_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsBloc>()..add(const LoadSettings()),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoaded) {
                return TextButton(
                  onPressed: () {
                    context.read<SettingsBloc>().add(const SaveSettings());
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.requiresReconnect
                      ? 'Settings saved! Reconnected with new voice.'
                      : 'Settings saved!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is SettingsLoaded || state is SettingsSaving || state is SettingsSaved) {
            final settings = state is SettingsLoaded
                ? state.settings
                : state is SettingsSaving
                    ? state.settings
                    : (state as SettingsSaved).settings;
            final deviceInfo = state is SettingsLoaded
                ? state.deviceInfo
                : state is SettingsSaving
                    ? state.deviceInfo
                    : (state as SettingsSaved).deviceInfo;
            final isSaving = state is SettingsSaving;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Info Section
                      _buildSectionHeader(theme, 'Device & Session'),
                      const SizedBox(height: 12),
                      _buildDeviceInfoCard(context, deviceInfo),
                      const SizedBox(height: 24),

                      // TTS Settings Section
                      _buildSectionHeader(theme, 'Voice Settings'),
                      const SizedBox(height: 12),
                      _buildTtsSettingsCard(context, settings),
                      const SizedBox(height: 24),

                      // System Prompts Section
                      _buildSectionHeader(theme, 'System Prompts'),
                      const SizedBox(height: 12),
                      const SystemPromptsSection(),
                      const SizedBox(height: 24),

                      // Reset Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                backgroundColor: AppColors.surfaceDark,
                                title: const Text(
                                  'Reset Settings',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                                content: const Text(
                                  'Are you sure you want to reset all settings to defaults?',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.read<SettingsBloc>().add(const ResetSettings());
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text(
                            'Reset to Defaults',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            );
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(const LoadSettings());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, dynamic deviceInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            'Session ID',
            deviceInfo.sessionId ?? 'Not connected',
            canCopy: deviceInfo.sessionId != null,
          ),
          const Divider(color: AppColors.surfaceVariant, height: 24),
          _buildInfoRow(context, 'Username', deviceInfo.username ?? 'Unknown'),
          const Divider(color: AppColors.surfaceVariant, height: 24),
          _buildInfoRow(
            context,
            'Connection',
            deviceInfo.isConnected ? 'Connected' : 'Disconnected',
            valueColor: deviceInfo.isConnected ? AppColors.success : AppColors.textSecondary,
          ),
          const Divider(color: AppColors.surfaceVariant, height: 24),
          _buildInfoRow(context, 'Device Type', _capitalizeFirst(deviceInfo.deviceType)),
          const Divider(color: AppColors.surfaceVariant, height: 24),
          _buildInfoRow(context, 'App Version', deviceInfo.appVersion),
          if (deviceInfo.currentTtsProvider != null) ...[
            const Divider(color: AppColors.surfaceVariant, height: 24),
            _buildInfoRow(
              context,
              'Current TTS',
              _getTtsDisplayName(
                deviceInfo.currentTtsProvider,
                deviceInfo.currentTtsVoiceId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool canCopy = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTtsSettingsCard(BuildContext context, dynamic settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: VoiceSelector(
        selectedProvider: settings.ttsProvider,
        selectedVoiceId: settings.ttsVoiceId,
        isCustomVoice: settings.isCustomVoice,
        customVoiceId: settings.customVoiceId,
        onProviderChanged: (provider) {
          context.read<SettingsBloc>().add(UpdateTtsProvider(provider));
        },
        onVoiceChanged: (voiceId) {
          context.read<SettingsBloc>().add(UpdateVoiceId(voiceId));
        },
        onCustomVoiceToggled: (isCustom) {
          context.read<SettingsBloc>().add(ToggleCustomVoice(isCustom));
        },
        onCustomVoiceIdChanged: (voiceId) {
          context.read<SettingsBloc>().add(UpdateCustomVoiceId(voiceId));
        },
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getTtsDisplayName(String? provider, String? voiceId) {
    if (provider == null) return 'Not configured';

    final providerName = VoiceOptions.getProvider(provider)?.name ?? provider;
    if (voiceId == null) return providerName;

    final voice = VoiceOptions.getVoice(provider, voiceId);
    if (voice != null) {
      return '$providerName - ${voice.name}';
    }

    // Custom voice ID
    final shortId = voiceId.length > 8 ? '${voiceId.substring(0, 8)}...' : voiceId;
    return '$providerName - $shortId';
  }
}
