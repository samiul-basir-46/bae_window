package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File
import java.io.FileOutputStream

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

                Log.d(TAG, "isPaired=$isPaired, imagePath=$imagePath")

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

                // Handle image
                var imageSet = false
                if (!imagePath.isNullOrEmpty()) {
                    val imgFile = File(imagePath)
                    Log.d(TAG, "Image file: $imagePath, exists=${imgFile.exists()}, size=${if (imgFile.exists()) imgFile.length() else 0}")

                    if (imgFile.exists() && imgFile.length() > 0) {
                        // Create a resized widget bitmap file and load it
                        val result = createWidgetBitmap(context, imgFile)
                        if (result != null) {
                            val (widgetFile, bitmap) = result
                            // Try URI approach first (more reliable for large images)
                            try {
                                val uri = Uri.fromFile(widgetFile)
                                Log.d(TAG, "Trying setImageViewUri: $uri")
                                views.setImageViewUri(R.id.widget_image, uri)
                                imageSet = true
                                Log.d(TAG, "Image set via URI")
                            } catch (e: Exception) {
                                Log.e(TAG, "setImageViewUri failed: ${e.message}")
                            }

                            // Also try bitmap approach as fallback/additional
                            if (!imageSet) {
                                try {
                                    Log.d(TAG, "Trying setImageViewBitmap: ${bitmap.width}x${bitmap.height}")
                                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                                    imageSet = true
                                    Log.d(TAG, "Image set via Bitmap")
                                } catch (e: Exception) {
                                    Log.e(TAG, "setImageViewBitmap failed: ${e.message}")
                                }
                            }

                            if (imageSet) {
                                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                                views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                            }

                            if (!imageSet) bitmap.recycle()
                        } else {
                            Log.e(TAG, "Failed to create widget bitmap")
                        }
                    } else {
                        Log.d(TAG, "Image file missing or empty")
                    }
                }

                if (!imageSet) {
                    Log.d(TAG, "Showing placeholder")
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
                    Log.e(TAG, "Error setting click handler: ${e.message}")
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d(TAG, "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $appWidgetId: ${e.message}", e)
            }
        }
    }

    /**
     * Resize the source image and save as a widget-optimized bitmap file.
     * Returns Pair(savedFile, bitmap) or null on failure.
     */
    private fun createWidgetBitmap(context: Context, sourceFile: File): Pair<File, Bitmap>? {
        return try {
            // First, get image dimensions
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(sourceFile.absolutePath, boundsOpts)

            if (boundsOpts.outWidth <= 0 || boundsOpts.outHeight <= 0) {
                Log.e(TAG, "Invalid image: w=${boundsOpts.outWidth}, h=${boundsOpts.outHeight}")
                return null
            }

            Log.d(TAG, "Source image: ${boundsOpts.outWidth}x${boundsOpts.outHeight}")

            // Calculate sample size to get roughly 300px on longest side
            val maxDim = maxOf(boundsOpts.outWidth, boundsOpts.outHeight)
            var sampleSize = 1
            while (maxDim / (sampleSize * 2) >= 300) {
                sampleSize *= 2
            }

            // Decode with sample size using ARGB_8888 for best compatibility
            val decodeOpts = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            val bitmap = BitmapFactory.decodeFile(sourceFile.absolutePath, decodeOpts)
            if (bitmap == null) {
                Log.e(TAG, "Failed to decode bitmap")
                return null
            }

            Log.d(TAG, "Decoded: ${bitmap.width}x${bitmap.height}, sampleSize=$sampleSize, byteCount=${bitmap.byteCount}")

            // Save as JPEG to widget-specific file in filesDir (accessible by widget)
            val outputFile = File(context.filesDir, "widget_image.jpg")
            FileOutputStream(outputFile).use { fos ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                fos.flush()
            }

            Log.d(TAG, "Widget bitmap saved: ${outputFile.absolutePath}, size=${outputFile.length()} bytes")
            Pair(outputFile, bitmap)
        } catch (e: Exception) {
            Log.e(TAG, "createWidgetBitmap error: ${e.message}", e)
            null
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OOM in createWidgetBitmap", e)
            null
        }
    }
}