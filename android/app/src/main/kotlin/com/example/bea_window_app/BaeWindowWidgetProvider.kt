package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews

class BaeWindowWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "BaeWindowWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.bae_window_widget_viewer)
                val isPaired = prefs.getBoolean("isPaired", false)
                val senderName = prefs.getString("senderName", "") ?: ""
                val footerDescription =
                    prefs.getString("footerDescription", "Swipe to view shared moments")
                        ?: "Swipe to view shared moments"
                val timestamp = prefs.getString("timestamp", "") ?: ""
                val avatarLetter = prefs.getString("avatarLetter", "B") ?: "B"

                views.setTextViewText(R.id.status_text, if (isPaired) "Paired" else "Solo")
                views.setTextViewText(R.id.sender_name_top, senderName)
                views.setTextViewText(R.id.footer_description, footerDescription)
                views.setTextViewText(R.id.widget_timestamp, timestamp)
                views.setTextViewText(R.id.avatar_circle, avatarLetter)
                views.setViewVisibility(R.id.status_dot, if (isPaired) View.VISIBLE else View.GONE)

                val serviceIntent = Intent(context, BaeWindowWidgetStackService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.widget_stack, serviceIntent)

                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                val templateFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val template = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    launchIntent,
                    templateFlags
                )
                views.setPendingIntentTemplate(R.id.widget_stack, template)

                appWidgetManager.updateAppWidget(appWidgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_stack)
            } catch (e: Exception) {
                Log.e(TAG, "Widget update failed for id $appWidgetId: ${e.message}", e)
            }
        }
    }
}
