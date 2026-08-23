import 'package:bam_bam_user/app/theme/colors_value.dart';
import 'package:bam_bam_user/app/theme/dimens.dart';
import 'package:bam_bam_user/app/theme/styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Time picker that only lists selectable (future) hours and minutes.
class RestrictedTimePicker {
  RestrictedTimePicker._();

  static const int _minuteStep = 5;

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay _ceilToNextStep(TimeOfDay time) {
    final remainder = time.minute % _minuteStep;
    if (remainder == 0) return time;

    var minute = time.minute + (_minuteStep - remainder);
    var hour = time.hour;
    if (minute >= 60) {
      minute = 0;
      hour = (hour + 1) % 24;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Next valid 5-minute slot from current clock time.
  static TimeOfDay minimumFromNow() {
    final now = DateTime.now();
    return _ceilToNextStep(TimeOfDay(hour: now.hour, minute: now.minute));
  }

  static TimeOfDay ceilToStep(TimeOfDay time) => _ceilToNextStep(time);

  static bool isBefore(TimeOfDay a, TimeOfDay b) => _toMinutes(a) < _toMinutes(b);

  static TimeOfDay later(TimeOfDay a, TimeOfDay b) =>
      isBefore(a, b) ? ceilToStep(b) : ceilToStep(a);

  static List<int> _hours(TimeOfDay? minTime) {
    if (minTime == null) {
      return List<int>.generate(24, (i) => i);
    }
    return List<int>.generate(24 - minTime.hour, (i) => minTime.hour + i);
  }

  static List<int> _minutesForHour(int hour, TimeOfDay? minTime) {
    final all = List<int>.generate(12, (i) => i * _minuteStep);
    if (minTime == null) return all;
    if (hour > minTime.hour) return all;
    if (hour < minTime.hour) return <int>[];
    return all.where((m) => m > minTime.minute).toList(growable: false);
  }

  static TimeOfDay _clampInitial(
    TimeOfDay initial,
    List<int> hours,
    TimeOfDay? minTime,
  ) {
    var hour = hours.contains(initial.hour) ? initial.hour : hours.first;
    var minutes = _minutesForHour(hour, minTime);
    if (minutes.isEmpty) {
      hour = hours.first;
      minutes = _minutesForHour(hour, minTime);
    }

    var minute = minutes.contains(initial.minute)
        ? initial.minute
        : minutes.first;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _format12h(int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    TimeOfDay? minTime,
    String title = 'Select time',
  }) async {
    final hours = _hours(minTime);
    if (hours.isEmpty) return null;

    var selected = _clampInitial(initialTime, hours, minTime);

    return showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            var minuteOptions = _minutesForHour(selected.hour, minTime);
            if (minuteOptions.isEmpty) {
              minuteOptions = _minutesForHour(hours.first, minTime);
              selected = TimeOfDay(hour: hours.first, minute: minuteOptions.first);
            }

            void setHour(int hour) {
              final nextMinutes = _minutesForHour(hour, minTime);
              if (nextMinutes.isEmpty) return;
              setState(() {
                selected = TimeOfDay(
                  hour: hour,
                  minute: nextMinutes.contains(selected.minute)
                      ? selected.minute
                      : nextMinutes.first,
                );
                minuteOptions = nextMinutes;
              });
            }

            void setMinute(int minute) {
              setState(() {
                selected = TimeOfDay(hour: selected.hour, minute: minute);
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimens.sixteen),
              ),
              backgroundColor: ColorsValue.whiteColor,
              child: Padding(
                padding: Dimens.edgeInsets20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Styles.txtBlackColorW40014),
                    Dimens.boxHeight16,
                    Center(
                      child: Container(
                        padding: Dimens.edgeInsets10,
                        decoration: BoxDecoration(
                          color: ColorsValue.appColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Dimens.eight),
                        ),
                        child: Text(
                          _format12h(selected.hour, selected.minute),
                          style: Styles.txtBlackColorW40014.copyWith(
                            fontSize: Dimens.twentyFour,
                            fontWeight: FontWeight.w600,
                            color: ColorsValue.appColor,
                          ),
                        ),
                      ),
                    ),
                    Dimens.boxHeight12,
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimeWheel(
                              label: 'Hour',
                              values: hours
                                  .map((h) => h.toString().padLeft(2, '0'))
                                  .toList(),
                              selectedValue:
                                  selected.hour.toString().padLeft(2, '0'),
                              onSelected: (index) => setHour(hours[index]),
                            ),
                          ),
                          Dimens.boxWidth8,
                          Expanded(
                            child: _TimeWheel(
                              label: 'Min',
                              values: minuteOptions
                                  .map((m) => m.toString().padLeft(2, '0'))
                                  .toList(),
                              selectedValue:
                                  selected.minute.toString().padLeft(2, '0'),
                              onSelected: (index) =>
                                  setMinute(minuteOptions[index]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Dimens.boxHeight8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: Styles.appColorw50014,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(selected),
                          child: Text(
                            'OK',
                            style: Styles.appColorw50014.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = values.indexOf(selectedValue).clamp(0, values.length - 1);

    return Column(
      children: [
        Text(label, style: Styles.txtG7Colors40014),
        Dimens.boxHeight4,
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: FixedExtentScrollController(initialItem: selectedIndex),
            itemExtent: 40,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: values.length,
              builder: (context, index) {
                final isSelected = index == selectedIndex;
                return Center(
                  child: Text(
                    values[index],
                    style: Styles.txtBlackColorW40014.copyWith(
                      fontSize: isSelected ? Dimens.twenty : Dimens.sixteen,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? ColorsValue.appColor
                          : ColorsValue.txtG7Color,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
