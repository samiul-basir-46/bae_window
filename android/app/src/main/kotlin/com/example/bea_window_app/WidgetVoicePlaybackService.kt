package com.example.bea_window_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.util.Log

class WidgetVoicePlaybackService : Service() {

    companion object {
        const val EXTRA_VOICE_URL = "voice_url"
        const val EXTRA_PARTNER_NAME = "partner_name"
        const val PREF_IS_VOICE_PLAYING = "isVoicePlaying"

        private const val TAG = "WidgetVoicePlayback"
        private const val CHANNEL_ID = "widget_voice_playback"
        private const val NOTIFICATION_ID = 9402
    }

    private var mediaPlayer: MediaPlayer? = null
    private var currentVoiceUrl: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val voiceUrl = intent?.getStringExtra(EXTRA_VOICE_URL)
        val partnerName = intent?.getStringExtra(EXTRA_PARTNER_NAME)
            ?.ifBlank { "Bae" }
            ?: "Bae"

        if (voiceUrl.isNullOrEmpty()) {
            stopPlayback()
            return START_NOT_STICKY
        }

        // Tapping the same voice card again acts as a stop button.
        if (currentVoiceUrl == voiceUrl && mediaPlayer != null) {
            stopPlayback()
            return START_NOT_STICKY
        }

        stopPlayerOnly()
        currentVoiceUrl = voiceUrl
        startForeground(NOTIFICATION_ID, buildNotification(partnerName))
        updateWidgetPlaybackState(true)

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setDataSource(voiceUrl)
                setOnPreparedListener { it.start() }
                setOnCompletionListener { stopPlayback() }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "Playback failed: what=$what extra=$extra")
                    stopPlayback()
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Could not start widget voice playback", e)
            stopPlayback()
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopPlayerOnly()
        updateWidgetPlaybackState(false)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(partnerName: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                9403,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("Voice note from $partnerName")
            .setContentText("Playing from your Bae Window widget")
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
        }
        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Widget voice playback",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Plays short voice notes from the home-screen widget"
            setSound(null, null)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun stopPlayerOnly() {
        mediaPlayer?.let { player ->
            runCatching { player.stop() }
            runCatching { player.reset() }
            runCatching { player.release() }
        }
        mediaPlayer = null
        currentVoiceUrl = null
    }

    private fun stopPlayback() {
        stopPlayerOnly()
        updateWidgetPlaybackState(false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun updateWidgetPlaybackState(isPlaying: Boolean) {
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(PREF_IS_VOICE_PLAYING, isPlaying)
            .apply()

        val manager = AppWidgetManager.getInstance(this)
        val provider = ComponentName(this, BaeWindowWidgetProvider::class.java)
        val widgetIds = manager.getAppWidgetIds(provider)
        if (widgetIds.isEmpty()) return

        sendBroadcast(
            Intent(this, BaeWindowWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
        )
    }
}
