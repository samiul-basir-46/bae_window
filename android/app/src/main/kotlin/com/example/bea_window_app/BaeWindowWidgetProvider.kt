package com.example.bea_window_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File

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
                val senderName = prefs.getString("senderName", "from Bae") ?: "from Bae"
                val partnerName = senderName.removePrefix("from ").ifBlank { "Bae" }
                val footerDescription =
                    prefs.getString("footerDescription", "Awaiting a shared moment")
                        ?: "Awaiting a shared moment"
                val timestamp = prefs.getString("timestamp", "") ?: ""
                val avatarLetter = prefs.getString("avatarLetter", "B") ?: "B"
                val latestType = prefs.getString("badgeText", "Image")
                    ?.lowercase()
                    ?: "image"

                views.setTextViewText(
                    R.id.status_text,
                    if (isPaired) "CONNECTED" else "SOLO MODE"
                )
                views.setTextViewText(R.id.sender_name_top, senderName)
                views.setTextViewText(R.id.footer_description, footerDescription)
                views.setTextViewText(R.id.widget_timestamp, timestamp)
                views.setTextViewText(R.id.avatar_circle, avatarLetter)
                views.setViewVisibility(R.id.status_dot, if (isPaired) View.VISIBLE else View.GONE)

                val clickIntent = when (latestType) {
                    "draw" -> {
                        bindVisualContent(
                            views = views,
                            imageViewId = R.id.widget_drawing_image,
                            imagePath = prefs.getString("drawingPath", null),
                            badge = "DRAW",
                            badgeBackground = R.drawable.widget_badge_draw,
                            icon = "🎨",
                            iconBackground = R.drawable.widget_icon_draw,
                            emptyTitle = "No drawing yet",
                            emptySubtitle = "Draw something special in Bae Window",
                            caption = "$partnerName drew this for you"
                        )
                        createAppLaunchPendingIntent(context, appWidgetId)
                    }

                    "voice" -> {
                        val voiceUrl = prefs.getString("voiceUrl", null)
                        bindVoiceContent(views, partnerName, !voiceUrl.isNullOrEmpty())
                        if (!voiceUrl.isNullOrEmpty()) {
                            createVoicePlaybackPendingIntent(
                                context = context,
                                appWidgetId = appWidgetId,
                                voiceUrl = voiceUrl,
                                partnerName = partnerName
                            )
                        } else {
                            createAppLaunchPendingIntent(context, appWidgetId)
                        }
                    }

                    else -> {
                        bindVisualContent(
                            views = views,
                            imageViewId = R.id.widget_photo_image,
                            imagePath = prefs.getString("imagePath", null),
                            badge = "IMAGE",
                            badgeBackground = R.drawable.widget_badge_image,
                            icon = "📷",
                            iconBackground = R.drawable.widget_icon_image,
                            emptyTitle = "No photo yet",
                            emptySubtitle = "Capture a moment in Bae Window",
                            caption = "A fresh moment from $partnerName"
                        )
                        createAppLaunchPendingIntent(context, appWidgetId)
                    }
                }

                views.setOnClickPendingIntent(R.id.center_container, clickIntent)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Widget update failed for id $appWidgetId: ${e.message}", e)
            }
        }
    }

    private fun bindVisualContent(
        views: RemoteViews,
        imageViewId: Int,
        imagePath: String?,
        badge: String,
        badgeBackground: Int,
        icon: String,
        iconBackground: Int,
        emptyTitle: String,
        emptySubtitle: String,
        caption: String
    ) {
        resetContentViews(views)
        views.setTextViewText(R.id.widget_content_badge, badge)
        views.setInt(R.id.widget_content_badge, "setBackgroundResource", badgeBackground)
        views.setInt(R.id.widget_content_icon, "setBackgroundResource", iconBackground)

        val bitmap = imagePath?.let(::loadSmallBitmap)
        if (bitmap != null) {
            views.setImageViewBitmap(imageViewId, bitmap)
            views.setViewVisibility(imageViewId, View.VISIBLE)
            views.setViewVisibility(R.id.widget_content_placeholder, View.GONE)
            views.setViewVisibility(R.id.widget_media_scrim, View.VISIBLE)
            views.setViewVisibility(R.id.widget_content_caption, View.VISIBLE)
            views.setTextViewText(R.id.widget_content_caption, caption)
        } else {
            views.setViewVisibility(R.id.widget_content_placeholder, View.VISIBLE)
            views.setTextViewText(R.id.widget_content_icon, icon)
            views.setTextViewText(R.id.widget_content_title, emptyTitle)
            views.setTextViewText(R.id.widget_content_subtitle, emptySubtitle)
        }
    }

    private fun bindVoiceContent(
        views: RemoteViews,
        partnerName: String,
        hasVoice: Boolean
    ) {
        resetContentViews(views)
        views.setTextViewText(R.id.widget_content_badge, "VOICE")
        views.setInt(
            R.id.widget_content_badge,
            "setBackgroundResource",
            R.drawable.widget_badge_voice
        )
        views.setInt(
            R.id.widget_content_icon,
            "setBackgroundResource",
            R.drawable.widget_icon_voice
        )
        views.setViewVisibility(R.id.widget_content_placeholder, View.VISIBLE)
        views.setTextViewText(R.id.widget_content_icon, if (hasVoice) "▶" else "🎙️")
        views.setTextViewText(
            R.id.widget_content_title,
            if (hasVoice) "Voice note from $partnerName" else "No voice note yet"
        )
        views.setTextViewText(
            R.id.widget_content_subtitle,
            if (hasVoice) "Tap to play here • app stays closed" else "Record one in Bae Window"
        )
    }

    private fun resetContentViews(views: RemoteViews) {
        views.setViewVisibility(R.id.widget_photo_image, View.GONE)
        views.setViewVisibility(R.id.widget_drawing_image, View.GONE)
        views.setViewVisibility(R.id.widget_media_scrim, View.GONE)
        views.setViewVisibility(R.id.widget_content_caption, View.GONE)
        views.setViewVisibility(R.id.widget_content_placeholder, View.GONE)
    }

    private fun createAppLaunchPendingIntent(
        context: Context,
        appWidgetId: Int
    ): PendingIntent {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            ?: Intent(context, MainActivity::class.java)

        return PendingIntent.getActivity(
            context,
            appWidgetId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createVoicePlaybackPendingIntent(
        context: Context,
        appWidgetId: Int,
        voiceUrl: String,
        partnerName: String
    ): PendingIntent {
        val playbackIntent = Intent(context, WidgetVoicePlaybackService::class.java).apply {
            putExtra(WidgetVoicePlaybackService.EXTRA_VOICE_URL, voiceUrl)
            putExtra(WidgetVoicePlaybackService.EXTRA_PARTNER_NAME, partnerName)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val requestCode = appWidgetId + 10_000

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(context, requestCode, playbackIntent, flags)
        } else {
            PendingIntent.getService(context, requestCode, playbackIntent, flags)
        }
    }

    private fun loadSmallBitmap(path: String): Bitmap? {
        val file = File(path)
        if (!file.exists() || file.length() == 0L) return null

        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            val maxDimension = maxOf(bounds.outWidth, bounds.outHeight)
            var sampleSize = 1
            while (maxDimension / (sampleSize * 2) >= 500) sampleSize *= 2

            BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply {
                    inSampleSize = sampleSize
                    inPreferredConfig = Bitmap.Config.RGB_565
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Could not load widget bitmap: ${e.message}")
            null
        }
    }
}
