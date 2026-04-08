package com.bitlynx.safely

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONArray
import org.json.JSONObject

class SafelyGeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return

        val transition = when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "enter"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "exit"
            else -> return
        }

        val metadata = readZoneMetadata(context)
        val triggeringGeofences = event.triggeringGeofences ?: return
        for (geofence in triggeringGeofences) {
            val zone = metadata[geofence.requestId] ?: continue
            writePendingEvent(context, zone, transition, event.triggeringLocation)

            if (transition == "enter" && zone.optString("type") == "unsafe") {
                if (geofenceNotificationsEnabled(context)) {
                    showUnsafeZoneNotification(context, zone.optString("name", "an unsafe zone"))
                }
                createFirestoreAlert(context, zone, event.triggeringLocation)
            }
        }
    }

    private fun geofenceNotificationsEnabled(context: Context): Boolean {
        return context
            .getSharedPreferences(SafelyGeofenceManager.NATIVE_PREFS, Context.MODE_PRIVATE)
            .getBoolean(SafelyGeofenceManager.OS_GEOFENCE_NOTIFICATIONS_ENABLED_KEY, true)
    }

    private fun readZoneMetadata(context: Context): Map<String, JSONObject> {
        val raw = context
            .getSharedPreferences(SafelyGeofenceManager.NATIVE_PREFS, Context.MODE_PRIVATE)
            .getString(SafelyGeofenceManager.OS_GEOFENCE_METADATA_KEY, "[]")
            ?: "[]"
        val array = JSONArray(raw)
        val zones = mutableMapOf<String, JSONObject>()
        for (index in 0 until array.length()) {
            val zone = array.optJSONObject(index) ?: continue
            val id = zone.optString("id")
            if (id.isNotEmpty()) {
                zones[id] = zone
            }
        }
        return zones
    }

    private fun writePendingEvent(
        context: Context,
        zone: JSONObject,
        transition: String,
        location: Location?
    ) {
        val payload = JSONObject()
            .put("zoneId", zone.optString("id"))
            .put("name", zone.optString("name"))
            .put("type", zone.optString("type"))
            .put("transition", transition)
            .put("lat", location?.latitude ?: zone.optDouble("lat"))
            .put("lng", location?.longitude ?: zone.optDouble("lng"))
            .put("updatedAt", System.currentTimeMillis())

        context
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putString("flutter.pending_geofence_event_json", payload.toString())
            .apply()
    }

    private fun showUnsafeZoneNotification(context: Context, zoneName: String) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                "Safely alerts",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val contentIntent = PendingIntent.getActivity(
            context,
            43021,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, ALERT_CHANNEL_ID)
        } else {
            android.app.Notification.Builder(context)
        }
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Unsafe zone detected")
            .setContentText("You entered $zoneName. Guardians can be alerted.")
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()

        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    private fun createFirestoreAlert(context: Context, zone: JSONObject, location: Location?) {
        val user = FirebaseAuth.getInstance().currentUser ?: return
        val firestore = FirebaseFirestore.getInstance()
        val userRef = firestore.collection("users").document(user.uid)

        userRef.get()
            .addOnSuccessListener { snapshot ->
                val name = snapshot.getString("name")?.takeIf { it.isNotBlank() } ?: "Safemate"
                val guardianIds = snapshot.get("guardianIds") as? List<*> ?: emptyList<Any>()
                val batteryLevel = (snapshot.get("batteryLevel") as? Number)?.toInt()
                val alertId = "geofence_${System.currentTimeMillis()}"
                val alert = hashMapOf<String, Any?>(
                    "id" to alertId,
                    "userId" to user.uid,
                    "guardianIds" to guardianIds.filterIsInstance<String>(),
                    "type" to "geofence",
                    "status" to "active",
                    "title" to "Entered unsafe zone",
                    "description" to "$name entered ${zone.optString("name", "an unsafe zone")}.",
                    "timestamp" to Timestamp.now(),
                    "locationLat" to (location?.latitude ?: zone.optDouble("lat")),
                    "locationLng" to (location?.longitude ?: zone.optDouble("lng")),
                    "batteryLevel" to batteryLevel,
                    "audioUrl" to null,
                    "acknowledgedBy" to null,
                    "acknowledgedAt" to null,
                    "canceledByUser" to false,
                    "resolvedAt" to null
                )
                firestore.collection("alerts").document(alertId).set(alert)
                    .addOnSuccessListener { clearPendingEvent(context) }
            }
    }

    private fun clearPendingEvent(context: Context) {
        context
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .remove("flutter.pending_geofence_event_json")
            .apply()
    }

    private companion object {
        const val ALERT_CHANNEL_ID = "safely_alerts"
    }
}
