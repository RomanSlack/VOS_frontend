import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';

class RecurrenceBuilderDialog extends StatefulWidget {
  final RecurrenceRule? initialRule;

  const RecurrenceBuilderDialog({
    super.key,
    this.initialRule,
  });

  @override
  State<RecurrenceBuilderDialog> createState() => _RecurrenceBuilderDialogState();
}

class _RecurrenceBuilderDialogState extends State<RecurrenceBuilderDialog> {
  RecurrenceMode _mode = RecurrenceMode.simple;
  String _freq = 'DAILY';
  int _interval = 1;
  EndType _endType = EndType.never;
  int? _count;
  DateTime? _until;
  List<String> _selectedWeekdays = [];
  List<int> _selectedMonthDays = [];

  late TextEditingController _intervalController;
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();

    if (widget.initialRule != null) {
      final rule = widget.initialRule!;
      _freq = rule.freq.toUpperCase();
      _interval = rule.interval ?? 1;
      _selectedWeekdays = rule.byWeekday ?? [];
      _selectedMonthDays = rule.byMonthday ?? [];

      if (rule.count != null) {
        _endType = EndType.afterOccurrences;
        _count = rule.count;
      } else if (rule.until != null) {
        _endType = EndType.onDate;
        _until = rule.until;
      }
    }

    _intervalController = TextEditingController(text: _interval.toString());
    _countController = TextEditingController(text: _count?.toString() ?? '');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF303030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Set Recurrence',
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF757575)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mode switcher
            Row(
              children: [
                Expanded(
                  child: _buildModeButton('Simple', RecurrenceMode.simple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeButton('Advanced', RecurrenceMode.advanced),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: _mode == RecurrenceMode.simple
                    ? _buildSimpleMode()
                    : _buildAdvancedMode(),
              ),
            ),

            const SizedBox(height: 24),

            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildPreview(),
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF757575)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveRecurrence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, RecurrenceMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick presets
        _buildPresetButton('Daily', 'DAILY', 1),
        const SizedBox(height: 8),
        _buildPresetButton('Weekly', 'WEEKLY', 1),
        const SizedBox(height: 8),
        _buildPresetButton('Monthly', 'MONTHLY', 1),
        const SizedBox(height: 8),
        _buildPresetButton('Yearly', 'YEARLY', 1),
        const SizedBox(height: 24),

        // End condition
        _buildEndConditionSection(),
      ],
    );
  }

  Widget _buildAdvancedMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency
        const Text(
          'Frequency',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _freq,
          dropdownColor: const Color(0xFF424242),
          style: const TextStyle(color: Color(0xFFEDEDED)),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
          items: ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']
              .map((freq) => DropdownMenuItem(
                    value: freq,
                    child: Text(freq.toLowerCase().capitalize()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _freq = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        // Interval
        const Text(
          'Repeat every',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _intervalController,
                style: const TextStyle(color: Color(0xFFEDEDED)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00BCD4)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _interval = int.tryParse(value) ?? 1;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getIntervalUnit(),
              style: const TextStyle(color: Color(0xFF757575)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekly: Day of week selector
        if (_freq == 'WEEKLY') ...[
          const Text(
            'Repeat on',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildWeekdaySelector(),
          const SizedBox(height: 16),
        ],

        // Monthly: Day of month selector
        if (_freq == 'MONTHLY') ...[
          const Text(
            'Day of month',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildMonthDaySelector(),
          const SizedBox(height: 16),
        ],

        // End condition
        _buildEndConditionSection(),
      ],
    );
  }

  Widget _buildPresetButton(String label, String freq, int interval) {
    final isSelected = _freq == freq && _interval == interval && _mode == RecurrenceMode.simple;
    return GestureDetector(
      onTap: () {
        setState(() {
          _freq = freq;
          _interval = interval;
          _intervalController.text = interval.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.2) : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF757575),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFFEDEDED),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    const weekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = weekdays[index];
        final isSelected = _selectedWeekdays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWeekdays.remove(day);
              } else {
                _selectedWeekdays.add(day);
              }
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF424242),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Text(
                weekdayLabels[index][0],
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (index) {
        final day = index + 1;
        final isSelected = _selectedMonthDays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMonthDays.remove(day);
              } else {
                _selectedMonthDays.add(day);
              }
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF424242),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEndConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ends',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<EndType>(
          title: const Text('Never', style: TextStyle(color: Color(0xFFEDEDED))),
          value: EndType.never,
          groupValue: _endType,
          onChanged: (value) => setState(() => _endType = value!),
          activeColor: const Color(0xFF00BCD4),
        ),
        RadioListTile<EndType>(
          title: Row(
            children: [
              const Text('After', style: TextStyle(color: Color(0xFFEDEDED))),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _countController,
                  style: const TextStyle(color: Color(0xFFEDEDED)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: _endType == EndType.afterOccurrences,
                  decoration: InputDecoration(
                    hintText: '10',
                    hintStyle: const TextStyle(color: Color(0xFF757575)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00BCD4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _count = int.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('occurrences', style: TextStyle(color: Color(0xFFEDEDED))),
            ],
          ),
          value: EndType.afterOccurrences,
          groupValue: _endType,
          onChanged: (value) => setState(() => _endType = value!),
          activeColor: const Color(0xFF00BCD4),
        ),
        RadioListTile<EndType>(
          title: Row(
            children: [
              const Text('On', style: TextStyle(color: Color(0xFFEDEDED))),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _endType == EndType.onDate ? _pickEndDate : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _endType == EndType.onDate
                        ? const Color(0xFF424242)
                        : const Color(0xFF303030),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    _until != null
                        ? DateFormat('MMM dd, yyyy').format(_until!)
                        : 'Select date',
                    style: TextStyle(
                      color: _endType == EndType.onDate
                          ? const Color(0xFFEDEDED)
                          : const Color(0xFF757575),
                    ),
                  ),
                ),
              ),
            ],
          ),
          value: EndType.onDate,
          groupValue: _endType,
          onChanged: (value) => setState(() => _endType = value!),
          activeColor: const Color(0xFF00BCD4),
        ),
      ],
    );
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _until = picked;
      });
    }
  }

  String _getIntervalUnit() {
    switch (_freq) {
      case 'DAILY':
        return _interval == 1 ? 'day' : 'days';
      case 'WEEKLY':
        return _interval == 1 ? 'week' : 'weeks';
      case 'MONTHLY':
        return _interval == 1 ? 'month' : 'months';
      case 'YEARLY':
        return _interval == 1 ? 'year' : 'years';
      default:
        return '';
    }
  }

  String _buildPreview() {
    final buffer = StringBuffer();

    switch (_freq) {
      case 'DAILY':
        buffer.write(_interval == 1 ? 'Every day' : 'Every $_interval days');
        break;
      case 'WEEKLY':
        buffer.write(_interval == 1 ? 'Every week' : 'Every $_interval weeks');
        if (_selectedWeekdays.isNotEmpty) {
          buffer.write(' on ${_selectedWeekdays.join(', ')}');
        }
        break;
      case 'MONTHLY':
        buffer.write(_interval == 1 ? 'Every month' : 'Every $_interval months');
        if (_selectedMonthDays.isNotEmpty) {
          buffer.write(' on day ${_selectedMonthDays.join(', ')}');
        }
        break;
      case 'YEARLY':
        buffer.write(_interval == 1 ? 'Every year' : 'Every $_interval years');
        break;
    }

    switch (_endType) {
      case EndType.never:
        // No additional text
        break;
      case EndType.afterOccurrences:
        if (_count != null) {
          buffer.write(', $_count times');
        }
        break;
      case EndType.onDate:
        if (_until != null) {
          buffer.write(' until ${DateFormat('MMM dd, yyyy').format(_until!)}');
        }
        break;
    }

    return buffer.toString();
  }

  void _saveRecurrence() {
    final rule = RecurrenceRule(
      freq: _freq,
      interval: _interval > 1 ? _interval : null,
      count: _endType == EndType.afterOccurrences ? _count : null,
      until: _endType == EndType.onDate ? _until : null,
      byWeekday: _freq == 'WEEKLY' && _selectedWeekdays.isNotEmpty
          ? _selectedWeekdays
          : null,
      byMonthday: _freq == 'MONTHLY' && _selectedMonthDays.isNotEmpty
          ? _selectedMonthDays
          : null,
    );

    Navigator.pop(context, rule);
  }
}

enum RecurrenceMode {
  simple,
  advanced,
}

enum EndType {
  never,
  afterOccurrences,
  onDate,
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
