import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/planner_event.dart';

class AddEditEventDialog extends StatefulWidget {
  final PlannerEvent? event;
  final String? initialDate;

  const AddEditEventDialog({
    super.key,
    this.event,
    this.initialDate,
  });

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedEventType;
  late String _targetDate;
  String? _startTime;
  String? _endTime;
  late String _priority;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _selectedEventType = event?.eventType ?? PlannerEvent.eventTypes.first;
    _targetDate = event?.targetDate ??
        widget.initialDate ??
        DateTime.now().toIso8601String().split('T').first;
    _startTime = event?.startTime;
    _endTime = event?.endTime;
    _priority = event?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_targetDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';

      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final updated = PlannerEvent(
      id: widget.event?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      eventType: _selectedEventType,
      targetDate: _targetDate,
      startTime: _startTime,
      endTime: _endTime,
      isCompleted: widget.event?.isCompleted ?? false,
      priority: _priority,
      createdAt: widget.event?.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: SizedBox(
        width: 540,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.lightPurple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditing ? 'Edit Event' : 'Schedule Future Event',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.mutedText, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 14),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter event title'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Event Title *',
                            hintText:
                                'e.g. Google Campus Placement Drive, Trees & DP Sprint...',
                            labelStyle:
                                const TextStyle(color: AppColors.secondaryText),
                            filled: true,
                            fillColor: AppColors.secondaryCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Event Type & Priority
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedEventType,
                                isExpanded: true,
                                dropdownColor: AppColors.secondaryCard,
                                style: const TextStyle(
                                    color: AppColors.primaryText, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  labelStyle: const TextStyle(
                                      color: AppColors.secondaryText),
                                  filled: true,
                                  fillColor: AppColors.secondaryCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                                items: PlannerEvent.eventTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type,
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedEventType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _priority,
                                isExpanded: true,
                                dropdownColor: AppColors.secondaryCard,
                                style: const TextStyle(
                                    color: AppColors.primaryText, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  labelStyle: const TextStyle(
                                      color: AppColors.secondaryText),
                                  filled: true,
                                  fillColor: AppColors.secondaryCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                                items: PlannerEvent.priorities.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _priority = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Date Picker Button
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_rounded,
                                        size: 18, color: AppColors.lightPurple),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Target Date *',
                                            style: TextStyle(
                                                color: AppColors.secondaryText,
                                                fontSize: 11)),
                                        Text(_targetDate,
                                            style: const TextStyle(
                                                color: AppColors.primaryText,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: AppColors.secondaryText),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Start & End Time Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: true),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 16,
                                          color: AppColors.secondaryText),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Start Time',
                                                style: TextStyle(
                                                    color:
                                                        AppColors.secondaryText,
                                                    fontSize: 10.5)),
                                            Text(_startTime ?? 'Not set',
                                                style: TextStyle(
                                                  color: _startTime != null
                                                      ? AppColors.primaryText
                                                      : AppColors.mutedText,
                                                  fontSize: 12.5,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: false),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 16,
                                          color: AppColors.secondaryText),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('End Time',
                                                style: TextStyle(
                                                    color:
                                                        AppColors.secondaryText,
                                                    fontSize: 10.5)),
                                            Text(_endTime ?? 'Not set',
                                                style: TextStyle(
                                                  color: _endTime != null
                                                      ? AppColors.primaryText
                                                      : AppColors.mutedText,
                                                  fontSize: 12.5,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Description / Milestones',
                            hintText:
                                'Round 1 Coding, Round 2 Tech interview, topics to revise...',
                            labelStyle:
                                const TextStyle(color: AppColors.secondaryText),
                            filled: true,
                            fillColor: AppColors.secondaryCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        isEditing ? 'Save Event' : 'Schedule Event',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
