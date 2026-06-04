package com.example.aiva

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createIncomingCallChannel()
    }

    /**
     * High-importance notification channel for AIVA appointment calls. The backend
     * sends the `incoming_call` FCM notification on this channel id; a HIGH-importance
     * channel with a ringtone is what makes Android render it as a heads-up that rings
     * (heads-up + sound is governed by the channel on Android 8+, not the message).
     * Created once on first launch; channel settings are immutable afterwards.
     */
    private fun createIncomingCallChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Incoming calls",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Appointment calls AIVA places on your behalf"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 1000, 800, 1000)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            val ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(ringtone, attrs)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "incoming_calls"
    }
}
