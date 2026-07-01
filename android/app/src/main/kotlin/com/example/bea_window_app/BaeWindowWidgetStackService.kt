package com.example.bea_window_app

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.io.File

class BaeWindowWidgetStackService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsService.RemoteViewsFactory {
        return BaeWindowWidgetStackFactory(applicationContext)
    }
}

private class BaeWindowWidgetStackFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private val prefs
        get() = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

    override fun onCreate() = Unit

    override fun onDataSetChanged() = Unit

    override fun onDestroy() = Unit

    override fun getCount(): Int = 3

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.bae_window_widget_page)

        when (position) {
            0 -> bindVisualPage(
                views = views,
                filePath = prefs.getString("imagePath", null),
                badge = "Image",
                icon = "📷",
                emptyTitle = "No photo yet",
                emptySubtitle = "Open Bae Window to share a photo"
            )

            1 -> bindVisualPage(
                views = views,
                filePath = prefs.getString("drawingPath", null),
                badge = "Draw",
                icon = "🎨",
                emptyTitle = "No drawing yet",
                emptySubtitle = "Open Bae Window to draw something"
            )

            else -> bindVoicePage(views)
        }

        val fillInIntent = Intent().apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("baewindow://home")
        }
        views.setOnClickFillInIntent(R.id.widget_page_root, fillInIntent)
        return views
    }

    private fun bindVisualPage(
        views: RemoteViews,
        filePath: String?,
        badge: String,
        icon: String,
        emptyTitle: String,
        emptySubtitle: String
    ) {
        views.setTextViewText(R.id.widget_page_badge, badge)
        val bitmap = filePath?.let(::loadSmallBitmap)

        if (bitmap != null) {
            views.setImageViewBitmap(R.id.widget_page_image, bitmap)
            views.setViewVisibility(R.id.widget_page_image, View.VISIBLE)
            views.setViewVisibility(R.id.widget_page_placeholder, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_page_image, View.GONE)
            views.setViewVisibility(R.id.widget_page_placeholder, View.VISIBLE)
            views.setTextViewText(R.id.widget_page_icon, icon)
            views.setTextViewText(R.id.widget_page_title, emptyTitle)
            views.setTextViewText(R.id.widget_page_subtitle, emptySubtitle)
        }
    }

    private fun bindVoicePage(views: RemoteViews) {
        val hasVoice = !prefs.getString("voiceUrl", null).isNullOrEmpty()
        views.setTextViewText(R.id.widget_page_badge, "Voice")
        views.setViewVisibility(R.id.widget_page_image, View.GONE)
        views.setViewVisibility(R.id.widget_page_placeholder, View.VISIBLE)
        views.setTextViewText(R.id.widget_page_icon, "🎙️")
        views.setTextViewText(
            R.id.widget_page_title,
            if (hasVoice) "Voice message from Bae" else "No voice message yet"
        )
        views.setTextViewText(
            R.id.widget_page_subtitle,
            if (hasVoice) "Tap to open and listen" else "Open Bae Window to record one"
        )
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
            while (maxDimension / (sampleSize * 2) >= 300) sampleSize *= 2

            BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply {
                    inSampleSize = sampleSize
                    inPreferredConfig = Bitmap.Config.RGB_565
                }
            )
        } catch (_: Exception) {
            null
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
