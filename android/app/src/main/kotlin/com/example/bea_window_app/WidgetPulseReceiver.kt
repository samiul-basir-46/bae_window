package com.example.bea_window_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.widget.Toast

class WidgetPulseReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        WidgetNativeShareService.sendPulse { success, message ->
            if (success) vibrateConfirmation(context)
            Toast.makeText(context.applicationContext, message, Toast.LENGTH_SHORT).show()
            pendingResult.finish()
        }
    }

    private fun vibrateConfirmation(context: Context) {
        @Suppress("DEPRECATION")
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(90, 170))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(90)
        }
    }
}
