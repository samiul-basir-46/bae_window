package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.widget.RemoteViews

class BaeWindowWidgetDockProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.bae_window_widget_dock)

            // Read values written by home_widget
            val partnerStatus = prefs.getString("dockPartnerStatus", "Bae's Phone")
            val isPaired = prefs.getBoolean("isPaired", false)
            val subtitle = if (isPaired) {
                "Tap an action • app stays closed"
            } else {
                prefs.getString("dockSubtitle", "Pair with your partner first")
            }

            views.setTextViewText(R.id.dock_partner_status, partnerStatus)
            views.setTextViewText(R.id.dock_subtitle, subtitle)
            bindDownloadedIcons(context, views)

            views.setOnClickPendingIntent(
                R.id.btn_camera,
                createActionPendingIntent(context, appWidgetId, WidgetQuickActionActivity.ACTION_CAMERA)
            )
            views.setOnClickPendingIntent(
                R.id.btn_draw,
                createActionPendingIntent(context, appWidgetId, WidgetQuickActionActivity.ACTION_DRAW)
            )
            views.setOnClickPendingIntent(
                R.id.btn_pulse,
                createPulsePendingIntent(context, appWidgetId)
            )
            views.setOnClickPendingIntent(
                R.id.btn_voice,
                createActionPendingIntent(context, appWidgetId, WidgetQuickActionActivity.ACTION_VOICE)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun bindDownloadedIcons(context: Context, views: RemoteViews) {
        val icons = listOf(
            R.id.btn_camera to "camera.png",
            R.id.btn_draw to "brush.png",
            R.id.btn_pulse to "pulse.png",
            R.id.btn_voice to "voice.png"
        )
        icons.forEach { (viewId, fileName) ->
            try {
                context.assets.open("flutter_assets/assets/icons/$fileName").use { input ->
                    BitmapFactory.decodeStream(input)?.let { bitmap ->
                        views.setImageViewBitmap(viewId, bitmap)
                        views.setInt(viewId, "setColorFilter", Color.WHITE)
                    }
                }
            } catch (_: Exception) {
                // XML fallback remains visible if a Flutter asset is unavailable.
            }
        }
    }

    private fun createActionPendingIntent(
        context: Context,
        appWidgetId: Int,
        action: String
    ): PendingIntent {
        val intent = Intent(context, WidgetQuickActionActivity::class.java).apply {
            putExtra(WidgetQuickActionActivity.EXTRA_ACTION, action)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            )
        }
        val requestCode = appWidgetId * 10 + action.hashCode()
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createPulsePendingIntent(
        context: Context,
        appWidgetId: Int
    ): PendingIntent {
        val intent = Intent(context, WidgetPulseReceiver::class.java).apply {
            action = "${context.packageName}.WIDGET_PULSE"
        }
        return PendingIntent.getBroadcast(
            context,
            appWidgetId + 50_000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
