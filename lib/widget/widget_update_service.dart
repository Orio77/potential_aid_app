import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:time_machine/time_machine.dart';

/// Serialises today's (or a specific date's) blocks into SharedPreferences so
/// the Android home-screen widget can read them without opening the app.
class WidgetUpdateService {
  static const _androidWidgetName =
      'com.example.potential_aid_app.ScheduleWidget';

  /// Update widget for today, ignoring the stored date offset.
  static Future<void> updateToday(AppDatabase db) async {
    final offset =
        (await HomeWidget.getWidgetData<int>('date_offset')) ?? 0;
    final date = LocalDate.today().addDays(offset);
    await update(db, date);
  }

  /// Serialise all blocks for [date] and push them to the widget.
  static Future<void> update(AppDatabase db, LocalDate date) async {
    try {
      final dateTime = date.toDateTimeUnspecified();
      final blocksWithTasks =
          await db.blockDao.getBlocksWithTasks(dateTime);

      final List<Map<String, dynamic>> blocksJson = [];

      for (final bwt in blocksWithTasks) {
        final project =
            await db.projectDao.getProjectById(bwt.block.projectId);
        final completionPct =
            await db.blockDao.getBlockCompletionPercentage(bwt.block.id);

        final endMinute =
            bwt.block.startMinuteOfDay + bwt.block.lengthMinutes;

        blocksJson.add({
          'id': bwt.block.id,
          'projectName': project?.name ?? 'Unknown Project',
          'timeRange':
              '${_fmt(bwt.block.startMinuteOfDay)} – ${_fmt(endMinute)}',
          'lengthMinutes': bwt.block.lengthMinutes,
          'isCompleted': completionPct != null,
          'completionPct': completionPct?.toInt() ?? 0,
          'tasks': (bwt.tasks ?? [])
              .map(
                (t) => {
                  'id': t.id,
                  'name': t.name,
                  'current': t.current,
                  'endGoal': t.endGoal,
                  'unit': t.unit ?? '',
                },
              )
              .toList(),
        });
      }

      final payload = jsonEncode({
        'dateLabel': _dateLabel(date),
        'dateOffset': (await HomeWidget.getWidgetData<int>('date_offset')) ?? 0,
        'blocks': blocksJson,
      });

      await HomeWidget.saveWidgetData<String>('schedule_json', payload);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidWidgetName,
      );
    } catch (_) {
      // Best-effort: never crash the caller.
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _fmt(int minutesFromMidnight) {
    final h = minutesFromMidnight ~/ 60;
    final m = minutesFromMidnight % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _dateLabel(LocalDate date) {
    final today = LocalDate.today();
    if (date == today) return 'Today';
    if (date == today.addDays(1)) return 'Tomorrow';
    if (date == today.subtractDays(1)) return 'Yesterday';
    return '${date.monthOfYear.toString().padLeft(2, '0')}/${date.dayOfMonth.toString().padLeft(2, '0')}/${date.year}';
  }
}
