package com.example.bea_window_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import java.io.File

class BaeWindowWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.bae_window_widget_viewer)
            
            // Read values written by home_widget
            val isPaired = prefs.getBoolean("isPaired", false)
            val status = prefs.getString("status", if (isPaired) "Paired" else "Solo Mode")
            val senderName = prefs.getString("senderName", if (isPaired) "from Bae" else "")
            val imagePath = prefs.getString("imagePath", null)
            val badgeText = prefs.getString("badgeText", null)
            val footerDescription = prefs.getString("footerDescription", if (isPaired) "Awaiting first snap" else "Connect with partner")
            val timestamp = prefs.getString("timestamp", "")
            val avatarLetter = prefs.getString("avatarLetter", "B")
            
            // Header
            views.setTextViewText(R.id.status_text, status)
            views.setViewVisibility(R.id.status_dot, if (isPaired) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.sender_name_top, senderName)
            
            // Center Image
            if (!imagePath.isNullOrEmpty()) {
                val imgFile = File(imagePath)
                if (imgFile.exists()) {
                    val bitmap = BitmapFactory.decodeFile(imgFile.absolutePath)
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                    views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_image, View.GONE)
                    views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                }
            } else {
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
            }
            
            // Badge (Image/Draw)
            if (!badgeText.isNullOrEmpty()) {
                views.setTextViewText(R.id.badge_text, badgeText)
                views.setViewVisibility(R.id.badge_text, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.badge_text, View.GONE)
            }
            
            // Footer
            views.setTextViewText(R.id.avatar_circle, avatarLetter)
            views.setTextViewText(R.id.footer_description, footerDescription)
            views.setTextViewText(R.id.widget_timestamp, timestamp)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
