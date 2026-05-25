import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_feedback.dart';

class ScheduleVisitSheet extends StatefulWidget {
  final dynamic customer;

  const ScheduleVisitSheet({
    super.key,
    required this.customer,
  });

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  final _db = DatabaseService();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedMonth = DateTime.now();
  String _selectedSlot = 'MORNING'; // 'MORNING', 'AFTERNOON', 'EVENING'
  final _purposeController = TextEditingController();

  final List<String> _monthsNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final List<Map<String, dynamic>> _slotsInfo = [
    {
      'id': 'MORNING',
      'label': 'Morning',
      'window': '09:00 AM - 12:00 PM',
      'icon': Icons.wb_twilight_rounded,
      'color': Colors.orange,
    },
    {
      'id': 'AFTERNOON',
      'label': 'Afternoon',
      'window': '12:00 PM - 03:00 PM',
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.amber,
    },
    {
      'id': 'EVENING',
      'label': 'Evening',
      'window': '03:00 PM - 06:00 PM',
      'icon': Icons.nightlight_round,
      'color': Colors.indigo,
    },
  ];

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final String timeSlotText = _slotsInfo.firstWhere((s) => s['id'] == _selectedSlot)['window'];
    final String visitNote = 'Scheduled follow-up visit for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} during $timeSlotText.';
    
    // Call database schedule
    _db.scheduleFollowUp(widget.customer.id, _selectedDate);
    
    // Add purpose note if entered
    final cust = _db.customers.firstWhere((c) => c.id == widget.customer.id);
    cust.notes.add(visitNote);
    if (_purposeController.text.trim().isNotEmpty) {
      cust.notes.add('Follow-up Purpose: ${_purposeController.text.trim()}');
    }

    Navigator.pop(context);

    CustomFeedback.showToast(
      context,
      'Follow-up scheduled successfully for ${widget.customer.name} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}!',
      type: 'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Follow-up',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a calendar slot to plan next field visit with ${widget.customer.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Selector
          Text(
            'SELECT FIELD VISIT DATE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.secondary,
                ),
          ),
          const SizedBox(height: 12),

          // Month Selector Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.primary, size: 20),
                  onPressed: _focusedMonth.year == DateTime.now().year && _focusedMonth.month == DateTime.now().month
                      ? null
                      : () {
                          setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                          });
                        },
                ),
                Text(
                  '${_monthsNames[_focusedMonth.month - 1]} ${_focusedMonth.year}'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weekdays Label Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Monthly Calendar Grid
          Builder(
            builder: (context) {
              final int year = _focusedMonth.year;
              final int month = _focusedMonth.month;
              final int daysInMonth = DateUtils.getDaysInMonth(year, month);
              
              // Find offset of first weekday (Monday starts at 1, so offset = weekday - 1)
              final DateTime firstDayOfMonth = DateTime(year, month, 1);
              final int offset = firstDayOfMonth.weekday - 1;
              
              final int totalItems = offset + daysInMonth;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.0,
                ),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  if (index < offset) {
                    return const SizedBox();
                  }

                  final int day = index - offset + 1;
                  final DateTime date = DateTime(year, month, day);
                  
                  // Disable past days
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final bool isPast = date.isBefore(today);
                  
                  final bool isSelected = _selectedDate.year == date.year &&
                                          _selectedDate.month == date.month &&
                                          _selectedDate.day == date.day;

                  return InkWell(
                    onTap: isPast
                        ? null
                        : () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: date.year == now.year && date.month == now.month && date.day == now.day && !isSelected
                            ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected || (date.year == now.year && date.month == now.month && date.day == now.day)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isPast
                                  ? AppTheme.secondary.withOpacity(0.35)
                                  : AppTheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Time Slots Visual Bento Grid
          Text(
            'PREFERRED VISIT TIME WINDOW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.secondary,
                ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _slotsInfo.map((slot) {
              final String slotId = slot['id'];
              final bool isSel = _selectedSlot == slotId;
              final IconData icon = slot['icon'];
              final Color iconColor = slot['color'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSlot = slotId;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.primary.withOpacity(0.04) : Colors.white,
                      border: Border.all(
                        color: isSel ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.8),
                        width: isSel ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? iconColor.withOpacity(0.15) : AppTheme.secondary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon, 
                            color: isSel ? iconColor : AppTheme.secondary, 
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSel ? AppTheme.primary : AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slot['window'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSel)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom observations text field
          Text(
            'VISIT PURPOSE / OBSERVATIONS (OPTIONAL)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.secondary,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'e.g. Confirm online bank transfer transaction, or collect balance dues...',
              hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.6), fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _handleConfirm,
              child: const Text(
                'CONFIRM VISIT PROTOCOL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
