import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/widget/widget_update_service.dart';
import 'package:time_machine/time_machine.dart';

/// Called by home_widget in a background isolate when the user taps the
/// prev-date or next-date buttons on the home-screen widget.
///
/// Registered in main.dart via:
///   HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimeMachine.initialize({'rootBundle': rootBundle});

  final int currentOffset =
      (await HomeWidget.getWidgetData<int>('date_offset')) ?? 0;

  int newOffset = currentOffset;
  if (uri?.host == 'date_prev') newOffset--;
  if (uri?.host == 'date_next') newOffset++;

  await HomeWidget.saveWidgetData<int>('date_offset', newOffset);

  final db = AppDatabase();
  try {
    final date = LocalDate.today().addDays(newOffset);
    await WidgetUpdateService.update(db, date);
  } finally {
    await db.close();
  }
}
