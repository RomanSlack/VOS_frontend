import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/reminders/bloc/reminders_bloc.dart';
import 'package:vos_app/features/reminders/bloc/reminders_event.dart';
import 'package:vos_app/presentation/widgets/recurrence_builder_dialog.dart';

enum ReminderDialogMode {
  timer,
  alarm,
  reminder,
}

class ReminderFormDialog extends StatefulWidget {
  final ReminderDialogMode mode;
  final Reminder? reminder;

  const ReminderFormDialog({
    super.key,
    required this.mode,
    this.reminder,
  });

  @override
  State<ReminderFormDialog> createState() => _ReminderFormDialogState();
}

class _ReminderFormDialogState extends State<ReminderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationHoursController;
  late TextEditingController _durationMinutesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  RecurrenceRule? _recurrenceRule;

  @override
  void initState() {
    super.initState();

    if (widget.reminder != null) {
      // Editing existing reminder
      final reminder = widget.reminder!;
      _titleController = TextEditingController(text: reminder.title);
      _descriptionController = TextEditingController(text: reminder.description ?? '');

      final triggerTime = reminder.triggerTime.toLocal();
      _selectedDate = DateTime(triggerTime.year, triggerTime.month, triggerTime.day);
      _selectedTime = TimeOfDay.fromDateTime(triggerTime);
      _recurrenceRule = reminder.recurrenceRule;
    } else {
      // Creating new reminder
      _titleController = TextEditingController(
        text: _getDefaultTitle(),
      );
      _descriptionController = TextEditingController();

      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
    }

    _durationHoursController = TextEditingController(text: '0');
    _durationMinutesController = TextEditingController(text: '15');
  }

  String _getDefaultTitle() {
    switch (widget.mode) {
      case ReminderDialogMode.timer:
        return 'Timer';
      case ReminderDialogMode.alarm:
        return 'Alarm';
      case ReminderDialogMode.reminder:
        return '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
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
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getModeIcon(),
                    color: const Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getModeTitle(),
                      style: const TextStyle(
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

              // Form content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Color(0xFFEDEDED)),
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Color(0xFFEDEDED)),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mode-specific inputs
                      if (widget.mode == ReminderDialogMode.timer)
                        _buildTimerInputs()
                      else if (widget.mode == ReminderDialogMode.alarm)
                        _buildAlarmInputs()
                      else
                        _buildReminderInputs(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                    onPressed: _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                    ),
                    child: Text(widget.reminder == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon() {
    switch (widget.mode) {
      case ReminderDialogMode.timer:
        return Icons.timer;
      case ReminderDialogMode.alarm:
        return Icons.alarm;
      case ReminderDialogMode.reminder:
        return Icons.notifications;
    }
  }

  String _getModeTitle() {
    if (widget.reminder != null) {
      return 'Edit Reminder';
    }
    switch (widget.mode) {
      case ReminderDialogMode.timer:
        return 'Set Timer';
      case ReminderDialogMode.alarm:
        return 'Set Alarm';
      case ReminderDialogMode.reminder:
        return 'Create Reminder';
    }
  }

  Widget _buildTimerInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hours',
                    style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _durationHoursController,
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Minutes',
                    style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _durationMinutesController,
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick duration buttons
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDurationChip('5 min', 0, 5),
            _buildQuickDurationChip('15 min', 0, 15),
            _buildQuickDurationChip('30 min', 0, 30),
            _buildQuickDurationChip('1 hour', 1, 0),
            _buildQuickDurationChip('2 hours', 2, 0),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDurationChip(String label, int hours, int minutes) {
    return FilterChip(
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _durationHoursController.text = hours.toString();
          _durationMinutesController.text = minutes.toString();
        });
      },
      backgroundColor: const Color(0xFF424242),
      selectedColor: const Color(0xFF2196F3),
      labelStyle: const TextStyle(color: Color(0xFFEDEDED)),
    );
  }

  Widget _buildAlarmInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time picker
        const Text(
          'Time',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF2196F3)),
                const SizedBox(width: 12),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker
        const Text(
          'Date',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(color: Color(0xFFEDEDED)),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFF757575), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time picker
        const Text(
          'Time',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickTime,
          child: InputDecorator(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(color: Color(0xFFEDEDED)),
                ),
                const Icon(Icons.access_time, color: Color(0xFF757575), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recurrence
        Row(
          children: [
            const Icon(Icons.repeat, color: Color(0xFF757575), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Recurrence',
              style: TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final rule = await showDialog<RecurrenceRule>(
                  context: context,
                  builder: (context) => RecurrenceBuilderDialog(
                    initialRule: _recurrenceRule,
                  ),
                );
                if (rule != null) {
                  setState(() {
                    _recurrenceRule = rule;
                  });
                }
              },
              child: Text(
                _recurrenceRule == null ? 'Set Recurrence' : 'Edit',
                style: const TextStyle(color: Color(0xFF2196F3)),
              ),
            ),
          ],
        ),
        if (_recurrenceRule != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _recurrenceRule!.toHumanReadable(),
                    style: const TextStyle(color: Color(0xFFEDEDED), fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF757575), size: 16),
                  onPressed: () {
                    setState(() {
                      _recurrenceRule = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.mode == ReminderDialogMode.timer) {
      final hours = int.tryParse(_durationHoursController.text) ?? 0;
      final minutes = int.tryParse(_durationMinutesController.text) ?? 0;

      if (hours == 0 && minutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a duration greater than 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final duration = Duration(hours: hours, minutes: minutes);
      context.read<RemindersBloc>().add(
            CreateTimer(
              title: _titleController.text,
              duration: duration,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
            ),
          );
    } else if (widget.mode == ReminderDialogMode.alarm) {
      final alarmTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // If alarm time has passed today, set it for tomorrow
      final now = DateTime.now();
      final finalAlarmTime = alarmTime.isBefore(now)
          ? alarmTime.add(const Duration(days: 1))
          : alarmTime;

      context.read<RemindersBloc>().add(
            CreateAlarm(
              title: _titleController.text,
              time: finalAlarmTime,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
            ),
          );
    } else {
      // Regular reminder
      final reminderTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (widget.reminder == null) {
        // Create new reminder
        final request = CreateReminderRequest(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          triggerTime: reminderTime.toUtc().toIso8601String(),
          recurrenceRule: _recurrenceRule,
          targetAgents: ['primary_agent'],
        );

        context.read<RemindersBloc>().add(CreateReminder(request));
      } else {
        // Edit existing reminder
        final request = EditReminderRequest(
          reminderId: widget.reminder!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          triggerTime: reminderTime.toUtc().toIso8601String(),
          recurrenceRule: _recurrenceRule,
          targetAgents: ['primary_agent'],
        );

        context.read<RemindersBloc>().add(EditReminder(request));
      }
    }

    Navigator.pop(context);
  }
}
