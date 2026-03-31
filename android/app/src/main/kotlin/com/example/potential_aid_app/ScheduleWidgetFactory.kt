package com.example.potential_aid_app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

data class WidgetBlock(
    val id: Int,
    val projectName: String,
    val timeRange: String,
    val lengthMinutes: Int,
    val isCompleted: Boolean,
    val completionPct: Int,
)

class ScheduleWidgetFactory(
    private val context: Context,
    private val appWidgetId: Int,
) : RemoteViewsService.RemoteViewsFactory {

    private val blocks = mutableListOf<WidgetBlock>()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        blocks.clear()
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("schedule_json", null) ?: return
        try {
            val root = JSONObject(json)
            val arr: JSONArray = root.optJSONArray("blocks") ?: return
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                blocks.add(
                    WidgetBlock(
                        id = obj.getInt("id"),
                        projectName = obj.optString("projectName", "—"),
                        timeRange = obj.optString("timeRange", ""),
                        lengthMinutes = obj.optInt("lengthMinutes", 60),
                        isCompleted = obj.optBoolean("isCompleted", false),
                        completionPct = obj.optInt("completionPct", 0),
                    )
                )
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {}

    override fun getCount(): Int = blocks.size

    override fun getViewAt(position: Int): RemoteViews {
        val block = blocks.getOrNull(position)
            ?: return RemoteViews(context.packageName, R.layout.widget_block_item)

        val rv = RemoteViews(context.packageName, R.layout.widget_block_item)

        rv.setTextViewText(R.id.block_project_name, block.projectName)
        rv.setTextViewText(R.id.block_time_info, block.timeRange)

        if (block.isCompleted) {
            rv.setTextViewText(R.id.block_completion_badge, "${block.completionPct}%")
            rv.setInt(R.id.block_completion_badge, "setVisibility", android.view.View.VISIBLE)
            rv.setInt(R.id.block_complete_btn, "setVisibility", android.view.View.GONE)
            rv.setInt(R.id.block_complete_btn, "setEnabled", 0)
        } else {
            rv.setInt(R.id.block_completion_badge, "setVisibility", android.view.View.GONE)
            rv.setInt(R.id.block_complete_btn, "setVisibility", android.view.View.VISIBLE)
            rv.setInt(R.id.block_complete_btn, "setEnabled", 1)

            // Fill-in intent: merged with the template PendingIntent set in ScheduleWidget
            val fillIn = Intent().apply {
                putExtra("blockId", block.id)
                putExtra("blockLength", block.lengthMinutes)
            }
            rv.setOnClickFillInIntent(R.id.block_complete_btn, fillIn)
        }

        return rv
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = blocks.getOrNull(position)?.id?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
