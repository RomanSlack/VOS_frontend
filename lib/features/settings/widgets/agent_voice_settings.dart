import 'package:flutter/material.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/data/voice_options.dart';
import 'package:vos_app/features/settings/models/agent_voice_model.dart';
import 'package:vos_app/features/settings/services/agent_voice_service.dart';

/// Widget for configuring per-agent voice settings
class AgentVoiceSettings extends StatefulWidget {
  const AgentVoiceSettings({super.key});

  @override
  State<AgentVoiceSettings> createState() => _AgentVoiceSettingsState();
}

class _AgentVoiceSettingsState extends State<AgentVoiceSettings> {
  late AgentVoiceService _service;
  List<AgentVoiceSetting>? _voices;
  bool _isLoading = true;
  String? _error;
  String? _expandedAgentId;

  @override
  void initState() {
    super.initState();
    _service = getIt<AgentVoiceService>();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final voices = await _service.getEffectiveVoices();
      setState(() {
        _voices = voices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVoice(
    String agentId,
    String ttsProvider,
    String voiceId,
    String? voiceName,
  ) async {
    try {
      await _service.setAgentVoice(
        agentId: agentId,
        ttsProvider: ttsProvider,
        voiceId: voiceId,
        voiceName: voiceName,
      );

      // Reload voices
      await _loadVoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice updated for ${AgentInfo.getAgent(agentId)?.displayName ?? agentId}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update voice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetVoice(String agentId) async {
    try {
      await _service.resetAgentVoice(agentId);
      await _loadVoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset voice for ${AgentInfo.getAgent(agentId)?.displayName ?? agentId}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset voice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              'Failed to load agent voices',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadVoices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with reset all button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Each agent can have a unique voice during calls',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        title: const Text(
                          'Reset All Voices',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: const Text(
                          'Reset all agents to their default voices?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Reset All',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _service.resetAllVoices();
                      await _loadVoices();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All agent voices reset to defaults'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Reset All',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceVariant, height: 1),

          // Agent list
          ...(_voices ?? []).map((voice) {
            final agentInfo = AgentInfo.getAgent(voice.agentId);
            final isExpanded = _expandedAgentId == voice.agentId;

            return Column(
              children: [
                _buildAgentTile(voice, agentInfo, isExpanded),
                if (isExpanded) _buildVoiceSelector(voice),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAgentTile(
    AgentVoiceSetting voice,
    AgentInfo? agentInfo,
    bool isExpanded,
  ) {
    final voiceName = _getVoiceDisplayName(voice);

    return InkWell(
      onTap: () {
        setState(() {
          _expandedAgentId = isExpanded ? null : voice.agentId;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Agent icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAgentIcon(voice.agentId),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Agent info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        agentInfo?.displayName ?? voice.agentId,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (voice.isCustom) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    voiceName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Expand indicator
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector(AgentVoiceSetting voice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: AppColors.backgroundDark.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Provider selector
          const Text(
            'Provider',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: VoiceOptions.providers.map((provider) {
              final isSelected = provider.id == voice.ttsProvider;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(provider.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      final defaultVoice = VoiceOptions.getDefaultVoice(provider.id);
                      if (defaultVoice != null) {
                        _updateVoice(
                          voice.agentId,
                          provider.id,
                          defaultVoice.id,
                          defaultVoice.name,
                        );
                      }
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.3),
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Voice selector
          const Text(
            'Voice',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...(VoiceOptions.getProvider(voice.ttsProvider)?.voices ?? []).map((voiceOption) {
                final isSelected = voiceOption.id == voice.voiceId;
                return ChoiceChip(
                  label: Text(voiceOption.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateVoice(
                        voice.agentId,
                        voice.ttsProvider,
                        voiceOption.id,
                        voiceOption.name,
                      );
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.3),
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                );
              }),
            ],
          ),

          // Reset button
          if (voice.isCustom) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _resetVoice(voice.agentId),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset to Default'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getVoiceDisplayName(AgentVoiceSetting voice) {
    if (voice.voiceName != null) {
      return '${_capitalizeFirst(voice.ttsProvider)} - ${voice.voiceName}';
    }

    final voiceOption = VoiceOptions.getVoice(voice.ttsProvider, voice.voiceId);
    if (voiceOption != null) {
      return '${_capitalizeFirst(voice.ttsProvider)} - ${voiceOption.name}';
    }

    final shortId = voice.voiceId.length > 8
        ? '${voice.voiceId.substring(0, 8)}...'
        : voice.voiceId;
    return '${_capitalizeFirst(voice.ttsProvider)} - $shortId';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  IconData _getAgentIcon(String agentId) {
    switch (agentId) {
      case 'primary_agent':
        return Icons.assistant;
      case 'weather_agent':
        return Icons.wb_sunny_outlined;
      case 'calendar_agent':
        return Icons.calendar_today;
      case 'notes_agent':
        return Icons.note_alt_outlined;
      case 'calculator_agent':
        return Icons.calculate_outlined;
      case 'search_agent':
        return Icons.search;
      case 'browser_agent':
        return Icons.language;
      default:
        return Icons.smart_toy_outlined;
    }
  }
}
