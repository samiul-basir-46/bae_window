package com.example.bea_window_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File

class BaeWindowWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "BaeWindowWidget"
        private const val MAX_WIDGET_IMAGE_SIZE = 400 // px, widget-এর জন্য যথেষ্ট sharp এবং নিরাপদ
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} widget(s)")

        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val allPrefs = prefs.all
        Log.d(TAG, "SharedPreferences keys: ${allPrefs.keys}")
        Log.d(TAG, "SharedPreferences values: $allPrefs")

        for (appWidgetId in appWidgetIds) {
            Log.d(TAG, "Updating widget id: $appWidgetId")
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

            Log.d(TAG, "isPaired=$isPaired, status=$status, senderName=$senderName")
            Log.d(TAG, "imagePath=$imagePath, badgeText=$badgeText")
            Log.d(TAG, "footer=$footerDescription, timestamp=$timestamp, avatar=$avatarLetter")

            // Header
            views.setTextViewText(R.id.status_text, status)
            views.setViewVisibility(R.id.status_dot, if (isPaired) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.sender_name_top, senderName)

            // Center Image
            if (!imagePath.isNullOrEmpty()) {
                val imgFile = File(imagePath)
                if (imgFile.exists()) {
                    Log.d(TAG, "Loading image from: $imagePath")
                    val bitmap = getResizedBitmap(imgFile.absolutePath, MAX_WIDGET_IMAGE_SIZE)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_image, bitmap)
                        views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                    } else {
                        Log.e(TAG, "Failed to decode bitmap from: $imagePath")
                        views.setViewVisibility(R.id.widget_image, View.GONE)
                        views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                    }
                } else {
                    Log.d(TAG, "Image file does not exist: $imagePath")
                    views.setViewVisibility(R.id.widget_image, View.GONE)
                    views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                }
            } else {
                Log.d(TAG, "No image path set, showing placeholder")
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
            Log.d(TAG, "Widget $appWidgetId updated successfully")
        }
    }

    /**
     * Decodes an image file into a Bitmap that is safely downsampled to fit
     * within Android's RemoteViews bitmap memory limit (~15.5MB).
     * Uses inSampleSize to avoid loading the full-resolution image into memory
     * before scaling, which is what was causing the OOM crash.
     */
    private fun getResizedBitmap(imagePath: String, maxSize: Int): Bitmap? {
        return try {
            // Step 1: Read only the image dimensions, not the pixel data
            val boundsOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(imagePath, boundsOptions)

            if (boundsOptions.outWidth <= 0 || boundsOptions.outHeight <= 0) {
                Log.e(TAG, "Invalid image dimensions for: $imagePath")
                return null
            }

            // Step 2: Calculate the largest inSampleSize that keeps both
            // dimensions >= maxSize (power-of-two downsampling is fast and
            // memory-efficient)
            var inSampleSize = 1
            var halfWidth = boundsOptions.outWidth / 2
            var halfHeight = boundsOptions.outHeight / 2
            while ((halfWidth / inSampleSize) >= maxSize && (halfHeight / inSampleSize) >= maxSize) {
                inSampleSize *= 2
            }

            // Step 3: Decode the actual (downsampled) bitmap
            val decodeOptions = BitmapFactory.Options().apply {
                this.inSampleSize = inSampleSize
            }
            val decodedBitmap = BitmapFactory.decodeFile(imagePath, decodeOptions)
                ?: run {
                    Log.e(TAG, "BitmapFactory.decodeFile returned null for: $imagePath")
                    return null
                }

            // Step 4: Final precise scale-down so we have a predictable,
            // small memory footprint regardless of the original aspect ratio
            val scaledBitmap = Bitmap.createScaledBitmap(decodedBitmap, maxSize, maxSize, true)

            // Recycle the intermediate bitmap if it's different from the final one,
            // to free memory immediately rather than waiting for GC
            if (scaledBitmap != decodedBitmap) {
                decodedBitmap.recycle()
            }

            scaledBitmap
        } catch (e: Exception) {
            Log.e(TAG, "Error resizing bitmap from $imagePath: ${e.message}", e)
            null
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OutOfMemoryError while resizing bitmap from $imagePath", e)
            null
        }
    }
}