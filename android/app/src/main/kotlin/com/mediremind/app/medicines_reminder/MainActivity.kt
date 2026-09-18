package com.mediremind.app.medicines_reminder

import android.content.Intent
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        setHighRefreshRate()
    }

    override fun onFlutterSurfaceViewCreated(flutterSurfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView)
        setHighRefreshRate()
    }

    private fun setHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val window = window ?: return
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            }

            val modes = display?.supportedModes
            val maxMode = modes?.maxByOrNull { it.refreshRate }

            val params = window.attributes
            if (maxMode != null) {
                params.preferredDisplayModeId = maxMode.modeId
            }
            params.preferredRefreshRate = maxMode?.refreshRate ?: 120f
            window.attributes = params

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setPreferMinimalPostProcessing(true)
            }
        }
    }
}
