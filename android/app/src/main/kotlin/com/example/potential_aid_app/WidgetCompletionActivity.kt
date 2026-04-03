package com.example.potential_aid_app

import android.content.Context
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Transparent activity launched when the user taps "Complete" on a block in
 * the home-screen widget.  It starts a Flutter engine running the separate
 * [widgetCompletionMain] Dart entry-point, which renders only the
 * CompleteBlockDialog over a transparent background.
 */
class WidgetCompletionActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Write the block data BEFORE Flutter initialises so the Dart side
        // can read it synchronously from SharedPreferences.
        val blockId = intent.getIntExtra("blockId", -1)
        val blockLength = intent.getIntExtra("blockLength", 60)

        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("pending_blockId", blockId)
            .putInt("pending_blockLength", blockLength)
            .apply()

        super.onCreate(savedInstanceState)
    }

    /** Run the minimal completion-dialog entry-point, not the full app. */
    override fun getDartEntrypointFunctionName(): String = "widgetCompletionMain"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        flutterEngine.plugins.add(HomeWidgetPlugin())
    }
}
