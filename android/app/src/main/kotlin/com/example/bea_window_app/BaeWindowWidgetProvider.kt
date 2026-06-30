package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
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
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} widget(s)")

        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            try {
                Log.d(TAG, "Updating widget id: $appWidgetId")
                val views = RemoteViews(context.packageName, R.layout.bae_window_widget_viewer)

                val isPaired = prefs.getBoolean("isPaired", false)
                val imagePath = prefs.getString("imagePath", null)
                val senderName = prefs.getString("senderName", "") ?: ""
                val footerDescription = prefs.getString("footerDescription", "Awaiting first snap") ?: "Awaiting first snap"
                val timestamp = prefs.getString("timestamp", "") ?: ""
                val avatarLetter = prefs.getString("avatarLetter", "B") ?: "B"
                val badgeText = prefs.getString("badgeText", null)

                Log.d(TAG, "isPaired=$isPaired, imagePath=$imagePath, sender=$senderName")

                // Set text views
                views.setTextViewText(R.id.status_text, if (isPaired) "Paired" else "Solo")
                views.setTextViewText(R.id.sender_name_top, senderName)
                views.setTextViewText(R.id.footer_description, footerDescription)
                views.setTextViewText(R.id.widget_timestamp, timestamp)
                views.setTextViewText(R.id.avatar_circle, avatarLetter)

                // Status dot visibility
                views.setViewVisibility(R.id.status_dot, if (isPaired) View.VISIBLE else View.GONE)

                // Badge
                if (!badgeText.isNullOrEmpty()) {
                    views.setTextViewText(R.id.badge_text, badgeText)
                    views.setViewVisibility(R.id.badge_text, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.badge_text, View.GONE)
                }

                // Handle image - use setImageViewBitmap with small bitmap
                var imageSet = false
                if (!imagePath.isNullOrEmpty()) {
                    val imgFile = java.io.File(imagePath)
                    Log.d(TAG, "Image file: exists=${imgFile.exists()}, size=${if (imgFile.exists()) imgFile.length() else 0}")

                    if (imgFile.exists() && imgFile.length() > 0) {
                        val bitmap = loadSmallBitmap(imgFile.absolutePath)
                        if (bitmap != null) {
                            Log.d(TAG, "Setting bitmap: ${bitmap.width}x${bitmap.height}, bytes=${bitmap.byteCount}")
                            views.setImageViewBitmap(R.id.widget_image, bitmap)
                            views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                            imageSet = true
                            Log.d(TAG, "Bitmap set successfully")
                        } else {
                            Log.e(TAG, "Failed to decode bitmap")
                        }
                    }
                }

                if (!imageSet) {
                    views.setViewVisibility(R.id.widget_image, View.GONE)
                    views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                }

                // Tap to open app
                try {
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        val pendingIntent = PendingIntent.getActivity(
                            context, appWidgetId, launchIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(R.id.center_container, pendingIntent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Click handler error: ${e.message}")
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d(TAG, "Widget $appWidgetId updated OK")
            } catch (e: Exception) {
                Log.e(TAG, "FATAL widget update error for $appWidgetId: ${e.message}", e)
            }
        }
    }

    /**
     * Load a small bitmap suitable for RemoteViews (max 150px, RGB_565)
     */
    private fun loadSmallBitmap(path: String): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            // Target ~150px on longest side to keep bitmap tiny
            val maxDim = maxOf(bounds.outWidth, bounds.outHeight)
            var sample = 1
            while (maxDim / (sample * 2) >= 150) sample *= 2

            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.RGB_565 // Half the memory
            }
            BitmapFactory.decodeFile(path, opts)
        } catch (e: Exception) {
            Log.e(TAG, "loadSmallBitmap error: ${e.message}")
            null
        }
    }
}