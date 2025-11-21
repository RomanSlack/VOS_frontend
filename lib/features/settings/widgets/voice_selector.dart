import 'package:flutter/material.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/data/voice_options.dart';

/// Widget for selecting TTS provider and voice
class VoiceSelector extends StatelessWidget {
  final String? selectedProvider;
  final String? selectedVoiceId;
  final bool isCustomVoice;
  final String? customVoiceId;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<bool> onCustomVoiceToggled;
  final ValueChanged<String> onCustomVoiceIdChanged;

  const VoiceSelector({
    super.key,
    required this.selectedProvider,
    required this.selectedVoiceId,
    required this.isCustomVoice,
    required this.customVoiceId,
    required this.onProviderChanged,
    required this.onVoiceChanged,
    required this.onCustomVoiceToggled,
    required this.onCustomVoiceIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider selector
        Text(
          'TTS Provider',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildProviderSelector(context),
        const SizedBox(height: 24),

        // Voice selector
        Text(
          'Voice',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // Toggle between predefined and custom
        Row(
          children: [
            Expanded(
              child: _buildVoiceModeChip(
                context,
                'Predefined',
                !isCustomVoice,
                () => onCustomVoiceToggled(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildVoiceModeChip(
                context,
                'Custom ID',
                isCustomVoice,
                () => onCustomVoiceToggled(true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Voice selection or custom input
        if (isCustomVoice)
          _buildCustomVoiceInput(context)
        else
          _buildVoiceDropdown(context),
      ],
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: VoiceOptions.providers.map((provider) {
          final isSelected = selectedProvider == provider.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onProviderChanged(provider.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceModeChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceDropdown(BuildContext context) {
    final provider = VoiceOptions.getProvider(selectedProvider ?? 'cartesia');
    if (provider == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVoiceId,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          style: const TextStyle(color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          items: provider.voices.map((voice) {
            return DropdownMenuItem<String>(
              value: voice.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voice.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (voice.description != null)
                    Text(
                      voice.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onVoiceChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomVoiceInput(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: customVoiceId),
      decoration: InputDecoration(
        hintText: 'Enter voice ID',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: onCustomVoiceIdChanged,
    );
  }
}
