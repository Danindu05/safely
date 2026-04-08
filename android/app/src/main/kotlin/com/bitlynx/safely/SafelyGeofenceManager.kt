package com.bitlynx.safely

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class SafelyGeofenceManager(private val context: Context) {
    private val appContext: Context = context.applicationContext
    private val geofencingClient = LocationServices.getGeofencingClient(appContext)

    fun registerGeofences(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        if (args == null) {
            result.error("bad_args", "Geofence arguments were missing.", null)
            return
        }

        if (!hasRequiredLocationPermissions()) {
            result.success(false)
            return
        }

        val zones = args["zones"] as? List<*> ?: emptyList<Any>()
        val geofences = zones.mapNotNull { value -> geofenceFrom(value as? Map<*, *>) }

        persistZoneMetadata(
            zones,
            args["geofenceNotificationsEnabled"] as? Boolean ?: true
        )

        if (geofences.isEmpty()) {
            clearGeofences(result)
            return
        }

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()

        geofencingClient.removeGeofences(geofencePendingIntent)
            .addOnCompleteListener {
                geofencingClient.addGeofences(request, geofencePendingIntent)
                    .addOnSuccessListener { result.success(true) }
                    .addOnFailureListener { result.success(false) }
            }
    }

    fun clearGeofences(result: MethodChannel.Result) {
        geofencingClient.removeGeofences(geofencePendingIntent)
            .addOnSuccessListener {
                persistZoneMetadata(emptyList<Any>(), true)
                result.success(true)
            }
            .addOnFailureListener {
                persistZoneMetadata(emptyList<Any>(), true)
                result.success(false)
            }
    }

    private fun geofenceFrom(zone: Map<*, *>?): Geofence? {
        if (zone == null) return null

        val id = (zone["id"] as? String)?.trim().orEmpty()
        val lat = (zone["lat"] as? Number)?.toDouble()
        val lng = (zone["lng"] as? Number)?.toDouble()
        val radiusMeters = (zone["radiusMeters"] as? Number)?.toFloat() ?: 100f
        if (id.isEmpty() || lat == null || lng == null || radiusMeters <= 0f) {
            return null
        }

        return Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lng, radiusMeters)
            .setTransitionTypes(
                Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT
            )
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .build()
    }

    private fun hasRequiredLocationPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val fineGranted = appContext.checkSelfPermission(
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            if (!fineGranted) return false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return appContext.checkSelfPermission(
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        }

        return true
    }

    private fun persistZoneMetadata(zones: List<*>, geofenceNotificationsEnabled: Boolean) {
        val array = JSONArray()
        for (value in zones) {
            val zone = value as? Map<*, *> ?: continue
            array.put(
                JSONObject()
                    .put("id", zone["id"] as? String ?: "")
                    .put("name", zone["name"] as? String ?: "zone")
                    .put("type", zone["type"] as? String ?: "")
                    .put("lat", (zone["lat"] as? Number)?.toDouble())
                    .put("lng", (zone["lng"] as? Number)?.toDouble())
                    .put("radiusMeters", (zone["radiusMeters"] as? Number)?.toDouble())
            )
        }

        appContext
            .getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(OS_GEOFENCE_METADATA_KEY, array.toString())
            .putBoolean(OS_GEOFENCE_NOTIFICATIONS_ENABLED_KEY, geofenceNotificationsEnabled)
            .apply()
    }

    private val geofencePendingIntent: PendingIntent
        get() {
            val intent = Intent(appContext, SafelyGeofenceReceiver::class.java)
                .setAction(ACTION_GEOFENCE_EVENT)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            return PendingIntent.getBroadcast(appContext, 43020, intent, flags)
        }

    companion object {
        const val CHANNEL_NAME = "com.bitlynx.safely/geofencing"
        const val ACTION_GEOFENCE_EVENT = "com.bitlynx.safely.ACTION_GEOFENCE_EVENT"
        const val NATIVE_PREFS = "safely_native_geofences"
        const val OS_GEOFENCE_METADATA_KEY = "os_geofence_metadata_json"
        const val OS_GEOFENCE_NOTIFICATIONS_ENABLED_KEY =
            "os_geofence_notifications_enabled"
    }
}
