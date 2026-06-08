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
        createNotificationChannels()
    }

    /**
     * Create AIVA's notification channels at first launch. A channel must exist (and
     * its importance is fixed once created) before a push can render on it — so the
     * backend's `AndroidNotification.channel_id` and the manifest's
     * `default_notification_channel_id` both point here. Channels persist across
     * process death, so once the app has been opened once they're always available.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return

        // Default channel for ALL ordinary pushes (reminders, mail, appointment
        // outcomes). HIGH importance => heads-up banner + sound, not a silent entry.
        if (manager.getNotificationChannel(CHANNEL_ALERTS) == null) {
            val alerts = NotificationChannel(
                CHANNEL_ALERTS,
                "AIVA Notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Reminders, important mail, and appointment updates"
                enableVibration(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(alerts)
        }

        // Incoming appointment calls: HIGH importance with a ringtone so it rings.
        if (manager.getNotificationChannel(CHANNEL_CALLS) == null) {
            val calls = NotificationChannel(
                CHANNEL_CALLS,
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
            manager.createNotificationChannel(calls)
        }
    }

    companion object {
        private const val CHANNEL_ALERTS = "aiva_alerts"
        private const val CHANNEL_CALLS = "incoming_calls"
    }
}
