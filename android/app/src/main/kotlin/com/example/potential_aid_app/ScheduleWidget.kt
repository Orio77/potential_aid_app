package com.example.potential_aid_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver

class ScheduleWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_DATE_PREV = "com.example.potential_aid_app.DATE_PREV"
        const val ACTION_DATE_NEXT = "com.example.potential_aid_app.DATE_NEXT"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ScheduleWidget::class.java)
            )
            val intent = Intent(context, ScheduleWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_DATE_PREV -> {
                context.sendBroadcast(
                    Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                        action = "es.antonborri.home_widget.action.BACKGROUND"
                        data = Uri.parse("schedulewidget://date_prev")
                    }
                )
            }
            ACTION_DATE_NEXT -> {
                context.sendBroadcast(
                    Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                        action = "es.antonborri.home_widget.action.BACKGROUND"
                        data = Uri.parse("schedulewidget://date_next")
                    }
                )
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val dateLabel = prefs.getString("schedule_json", null)
            ?.let { parseDate(it) } ?: "Today"

        val views = RemoteViews(context.packageName, R.layout.widget_schedule)

        // ── Date label ───────────────────────────────────────────────────────
        views.setTextViewText(R.id.widget_date_label, dateLabel)

        // ── Prev / Next date buttons ─────────────────────────────────────────
        val prevIntent = Intent(context, ScheduleWidget::class.java).apply {
            action = ACTION_DATE_PREV
        }
        views.setOnClickPendingIntent(
            R.id.widget_btn_prev,
            PendingIntent.getBroadcast(
                context, 0, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        val nextIntent = Intent(context, ScheduleWidget::class.java).apply {
            action = ACTION_DATE_NEXT
        }
        views.setOnClickPendingIntent(
            R.id.widget_btn_next,
            PendingIntent.getBroadcast(
                context, 1, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // ── Scrollable block list ─────────────────────────────────────────────
        val serviceIntent = Intent(context, ScheduleWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            // Each widget instance must have a unique URI for RemoteViewsService
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty_text)

        // Template PendingIntent: tapping "Complete" on a block item starts
        // WidgetCompletionActivity with blockId + blockLength filled in.
        val completionTemplate = Intent(context, WidgetCompletionActivity::class.java)
        val templatePi = PendingIntent.getActivity(
            context, 2, completionTemplate,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_list, templatePi)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
    }

    // Pulls the "dateLabel" field out of the JSON blob without a full parser.
    private fun parseDate(json: String): String {
        val match = Regex(""""dateLabel"\s*:\s*"([^"]+)"""").find(json)
        return match?.groupValues?.getOrNull(1) ?: "Today"
    }
}
