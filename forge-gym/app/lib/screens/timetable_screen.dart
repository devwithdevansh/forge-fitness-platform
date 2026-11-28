import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models.dart';
import '../ui/widgets.dart';

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _dayName = {
  'MON': 'Monday', 'TUE': 'Tuesday', 'WED': 'Wednesday',
  'THU': 'Thursday', 'FRI': 'Friday', 'SAT': 'Saturday', 'SUN': 'Sunday',
};

/// Read-only weekly timetable screen — shown to Members and Trainers.
/// Owners and Staff use the full CoachingScreen which also has edit controls.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late Future<_TimetableData> _future;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TimetableData> _load() async {
    final state = context.read<AppState>();
    final user = state.session?.user;
    final isMember = user?.isMember ?? false;

    if (isMember) {
      // Members already get slots via the portal endpoint
      final portal = await state.api.portal();
      return _TimetableData(slots: portal.slots, today: portal.weekday.toUpperCase().substring(0, 3));
    } else {
      // Trainers use the coach timetable endpoint
      final data = await state.api.timetable();
      final slots = asList(data['slots']).map(ClassSlot.fromJson).toList();
      return _TimetableData(slots: slots, today: str(data['today']));
    }
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return ForgePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'Weekly schedule',
            title: 'Timetable.',
            subtitle: 'All classes for the week. Tap a day to jump to it.',
            actions: [
              IconButton(tooltip: 'Refresh', onPressed: _reload, icon: const Icon(Icons.refresh, size: 19)),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<_TimetableData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const ForgeLoading(label: 'Loading timetable');
              }
              if (snapshot.hasError) return ErrorPanel(error: snapshot.error!, onRetry: _reload);
              final data = snapshot.data;
              if (data == null) return ErrorPanel(error: 'No timetable data.', onRetry: _reload);

              final today = data.today.toUpperCase();
              final selected = _selectedDay ?? today;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day-of-week tab strip
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _weekdays.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final d = _weekdays[i];
                        final isSelected = d == selected;
                        final isToday = d == today;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? ForgeColors.bone : ForgeColors.ink2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isToday && !isSelected ? ForgeColors.redHi : ForgeColors.line,
                                width: isToday && !isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              d,
                              style: ForgeTheme.mono(
                                9.5,
                                color: isSelected ? ForgeColors.ink : (isToday ? ForgeColors.redHi : ForgeColors.mute),
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Classes for selected day
                  _DayPanel(
                    day: selected,
                    dayName: _dayName[selected] ?? selected,
                    isToday: selected == today,
                    slots: data.slots.where((s) {
                      final d = s.day.toUpperCase();
                      return d == selected || d.startsWith(selected) || d == 'DAILY';
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // All days overview strip
                  ForgeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Full week',
                          subtitle: 'All classes at a glance.',
                        ),
                        const SizedBox(height: 10),
                        for (final d in _weekdays)
                          if (data.slots.any((s) {
                            final sd = s.day.toUpperCase();
                            return sd == d || sd.startsWith(d) || sd == 'DAILY';
                          }))
                            _WeekRow(
                              day: d,
                              isToday: d == today,
                              slots: data.slots.where((s) {
                                final sd = s.day.toUpperCase();
                                return sd == d || sd.startsWith(d) || sd == 'DAILY';
                              }).toList(),
                              onTap: () => setState(() => _selectedDay = d),
                            ),
                        if (!data.slots.any((s) => s.day.isNotEmpty))
                          const EmptyPanel(
                            title: 'No classes yet',
                            message: 'Your gym hasn\'t set up any classes yet.',
                            icon: Icons.calendar_month_outlined,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimetableData {
  const _TimetableData({required this.slots, required this.today});
  final List<ClassSlot> slots;
  final String today;
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.day,
    required this.dayName,
    required this.isToday,
    required this.slots,
  });
  final String day;
  final String dayName;
  final bool isToday;
  final List<ClassSlot> slots;

  @override
  Widget build(BuildContext context) {
    return ForgeCard(
      accent: isToday ? ForgeColors.red : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dayName.toUpperCase(),
                style: ForgeTheme.mono(
                  9.5,
                  color: isToday ? ForgeColors.redHi : ForgeColors.mute,
                  letterSpacing: 1.4,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                const StatusPill(label: 'today', color: ForgeColors.red, dense: true),
              ],
              const Spacer(),
              Text(
                '${slots.length} class${slots.length == 1 ? '' : 'es'}',
                style: ForgeTheme.mono(8.5, letterSpacing: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (slots.isEmpty)
            Text(
              'No classes scheduled. Rest day!',
              style: ForgeTheme.body(12, color: ForgeColors.mute),
            )
          else
            for (final slot in slots) _ClassTile(slot: slot),
        ],
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.slot});
  final ClassSlot slot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: ForgeColors.ink2,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: ForgeColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              timeLabel(slot.time),
              style: ForgeTheme.mono(9, color: ForgeColors.bone, letterSpacing: 0.3),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.name, style: ForgeTheme.body(13, weight: FontWeight.w600, color: ForgeColors.bone)),
                if (slot.trainerName != null && slot.trainerName!.isNotEmpty)
                  Text(
                    '${slot.durationMin} min · ${slot.trainerName}',
                    style: ForgeTheme.body(10.5, color: ForgeColors.mute),
                  )
                else
                  Text('${slot.durationMin} min', style: ForgeTheme.body(10.5, color: ForgeColors.mute)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.day, required this.isToday, required this.slots, required this.onTap});
  final String day;
  final bool isToday;
  final List<ClassSlot> slots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                day,
                style: ForgeTheme.mono(
                  9,
                  color: isToday ? ForgeColors.redHi : ForgeColors.mute,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: slots
                    .map((s) => StatusPill(label: '${timeLabel(s.time)} ${s.name}', color: ForgeColors.blue, dense: true))
                    .toList(),
              ),
            ),
            const Icon(Icons.chevron_right, size: 15, color: ForgeColors.mute),
          ],
        ),
      ),
    );
  }
}
