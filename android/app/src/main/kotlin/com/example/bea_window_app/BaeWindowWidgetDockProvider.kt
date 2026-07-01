package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
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
            val subtitle = prefs.getString("dockSubtitle", "Waiting for action...")

            views.setTextViewText(R.id.dock_partner_status, partnerStatus)
            views.setTextViewText(R.id.dock_subtitle, subtitle)

            // Set up PendingIntents for Deep Links
            views.setOnClickPendingIntent(R.id.btn_camera, createDeepLinkPendingIntent(context, "baewindow://camera"))
            views.setOnClickPendingIntent(R.id.btn_draw, createDeepLinkPendingIntent(context, "baewindow://draw"))
            views.setOnClickPendingIntent(R.id.btn_pulse, createDeepLinkPendingIntent(context, "baewindow://pulse"))
            views.setOnClickPendingIntent(R.id.btn_voice, createDeepLinkPendingIntent(context, "baewindow://voice"))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun createDeepLinkPendingIntent(context: Context, uriString: String): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString)).apply {
            `package` = context.packageName
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(context, uriString.hashCode(), intent, flags)
    }
}
