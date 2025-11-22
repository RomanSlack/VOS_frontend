import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  final String? selectedMemoryType;
  final String? selectedScope;
  final double? minImportance;
  final Function(String?) onMemoryTypeChanged;
  final Function(String?) onScopeChanged;
  final Function(double?) onImportanceChanged;

  const FilterPanel({
    Key? key,
    this.selectedMemoryType,
    this.selectedScope,
    this.minImportance,
    required this.onMemoryTypeChanged,
    required this.onScopeChanged,
    required this.onImportanceChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Memory Type Filter
          _buildDropdown(
            label: 'Memory Type',
            value: selectedMemoryType,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              const DropdownMenuItem(value: 'user_preference', child: Text('User Preference')),
              const DropdownMenuItem(value: 'user_fact', child: Text('User Fact')),
              const DropdownMenuItem(value: 'conversation_context', child: Text('Conversation')),
              const DropdownMenuItem(value: 'agent_procedure', child: Text('Procedure')),
              const DropdownMenuItem(value: 'knowledge', child: Text('Knowledge')),
              const DropdownMenuItem(value: 'event_pattern', child: Text('Event Pattern')),
              const DropdownMenuItem(value: 'error_handling', child: Text('Error Handling')),
              const DropdownMenuItem(value: 'proactive_action', child: Text('Proactive Action')),
            ],
            onChanged: onMemoryTypeChanged,
          ),
          const SizedBox(height: 12),
          // Scope Filter
          _buildDropdown(
            label: 'Scope',
            value: selectedScope,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Scopes')),
              DropdownMenuItem(value: 'shared', child: Text('Shared')),
              DropdownMenuItem(value: 'individual', child: Text('Individual')),
            ],
            onChanged: onScopeChanged,
          ),
          const SizedBox(height: 16),
          // Importance Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min Importance: ${minImportance != null ? (minImportance! * 100).toStringAsFixed(0) : 0}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Slider(
                value: minImportance ?? 0.0,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: const Color(0xFF00BCD4),
                inactiveColor: Colors.white.withOpacity(0.2),
                onChanged: onImportanceChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF424242),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: const Color(0xFF424242),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
