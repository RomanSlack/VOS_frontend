import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/calendar/bloc/calendar_event.dart';
import 'package:vos_app/presentation/widgets/recurrence_builder_dialog.dart';

class EventFormDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;

  const EventFormDialog({
    super.key,
    this.event,
    this.initialDate,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _allDay = false;

  RecurrenceRule? _recurrenceRule;
  List<int> _selectedReminders = [];

  final List<int> _reminderOptions = [15, 60, 1440, 10080]; // 15min, 1hr, 1day, 1week

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      // Editing existing event
      final event = widget.event!;
      _titleController = TextEditingController(text: event.title);
      _descriptionController = TextEditingController(text: event.description ?? '');
      _locationController = TextEditingController(text: event.location ?? '');

      final startLocal = event.startTime.toLocal();
      final endLocal = event.endTime.toLocal();

      _startDate = DateTime(startLocal.year, startLocal.month, startLocal.day);
      _startTime = TimeOfDay.fromDateTime(startLocal);
      _endDate = DateTime(endLocal.year, endLocal.month, endLocal.day);
      _endTime = TimeOfDay.fromDateTime(endLocal);
      _allDay = event.allDay;
      _recurrenceRule = event.recurrenceRule;
      _selectedReminders = event.autoReminders ?? [];
    } else {
      // Creating new event
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _locationController = TextEditingController();

      final initialDate = widget.initialDate ?? DateTime.now();
      _startDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
      _startTime = TimeOfDay.now();
      _endDate = _startDate;
      _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
        constraints: const BoxConstraints(maxHeight: 700),
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
                  Expanded(
                    child: Text(
                      widget.event == null ? 'Create Event' : 'Edit Event',
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
                            borderSide: BorderSide(color: Color(0xFF00BCD4)),
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

                      // All-day toggle
                      Row(
                        children: [
                          Checkbox(
                            value: _allDay,
                            onChanged: (value) {
                              setState(() {
                                _allDay = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF00BCD4),
                          ),
                          const Text(
                            'All-day event',
                            style: TextStyle(color: Color(0xFFEDEDED)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Start date/time
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'Start Date',
                              _startDate,
                              (date) => setState(() => _startDate = date),
                            ),
                          ),
                          if (!_allDay) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeField(
                                'Start Time',
                                _startTime,
                                (time) => setState(() => _startTime = time),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // End date/time
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'End Date',
                              _endDate,
                              (date) => setState(() => _endDate = date),
                            ),
                          ),
                          if (!_allDay) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeField(
                                'End Time',
                                _endTime,
                                (time) => setState(() => _endTime = time),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(color: Color(0xFFEDEDED)),
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF757575)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00BCD4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Color(0xFFEDEDED)),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00BCD4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recurrence
                      _buildRecurrenceSection(),
                      const SizedBox(height: 16),

                      // Auto-reminders
                      _buildRemindersSection(),
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
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                    ),
                    child: Text(widget.event == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark(),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF757575)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00BCD4)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(color: Color(0xFFEDEDED)),
            ),
            const Icon(Icons.calendar_today, color: Color(0xFF757575), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark(),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF757575)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00BCD4)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time.format(context),
              style: const TextStyle(color: Color(0xFFEDEDED)),
            ),
            const Icon(Icons.access_time, color: Color(0xFF757575), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                style: const TextStyle(color: Color(0xFF00BCD4)),
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

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.notifications, color: Color(0xFF757575), size: 20),
            SizedBox(width: 8),
            Text(
              'Auto-Reminders',
              style: TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderOptions.map((minutes) {
            final isSelected = _selectedReminders.contains(minutes);
            return FilterChip(
              label: Text(_formatReminderTime(minutes)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedReminders.add(minutes);
                  } else {
                    _selectedReminders.remove(minutes);
                  }
                });
              },
              backgroundColor: const Color(0xFF424242),
              selectedColor: const Color(0xFF00BCD4),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFEDEDED),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatReminderTime(int minutes) {
    if (minutes < 60) return '$minutes min before';
    if (minutes < 1440) return '${minutes ~/ 60} hr before';
    if (minutes < 10080) return '${minutes ~/ 1440} day before';
    return '${minutes ~/ 10080} week before';
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Combine date and time
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _allDay ? 0 : _startTime.hour,
      _allDay ? 1 : _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _allDay ? 23 : _endTime.hour,
      _allDay ? 59 : _endTime.minute,
    );

    if (widget.event == null) {
      // Create new event
      final request = CreateEventRequest(
        title: _titleController.text,
        startTime: startDateTime.toUtc().toIso8601String(),
        endTime: endDateTime.toUtc().toIso8601String(),
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        allDay: _allDay,
        recurrenceRule: _recurrenceRule,
        autoReminders: _selectedReminders.isEmpty ? null : _selectedReminders,
      );

      context.read<CalendarBloc>().add(CreateCalendarEvent(request));
    } else {
      // Update existing event
      final request = UpdateEventRequest(
        eventId: widget.event!.id,
        updateMode: 'all', // Default to updating all instances
        title: _titleController.text,
        startTime: startDateTime.toUtc().toIso8601String(),
        endTime: endDateTime.toUtc().toIso8601String(),
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        allDay: _allDay,
        recurrenceRule: _recurrenceRule,
        autoReminders: _selectedReminders.isEmpty ? null : _selectedReminders,
      );

      context.read<CalendarBloc>().add(UpdateCalendarEvent(request));
    }

    Navigator.pop(context);
  }
}
