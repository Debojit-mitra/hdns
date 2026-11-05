package com.hana.utils.hdns

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Manages the "Reduce Bright Colors" (Extra Dim) system setting.
 *
 * On Android 12+ (S+), `reduce_bright_colors_activated` is annotated with
 * @hide and is NOT @Readable, meaning non-system apps may get a
 * SecurityException when trying to READ it via the Settings.Secure Java API
 * (especially from Service contexts like TileService). Writing still works
 * with the WRITE_SECURE_SETTINGS permission.
 *
 * To work around this, we cache the last known state in SharedPreferences
 * and fall back to it when the system API read is blocked.
 */
object ExtraDimManager {
    const val SETTING_KEY = "reduce_bright_colors_activated"
    private const val PREFS = "extra_dim"
    private const val PREF_IS_ON = "is_on"
    private const val TAG = "HDNS_DIM"

    fun isSupported(): Boolean = Build.VERSION.SDK_INT >= 31

    private fun prefs(c: Context) =
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * Returns the current Extra Dim state.
     * Tries the system setting first; if that throws SecurityException
     * (common in TileService on S+), falls back to our cached value.
     */
    fun isOn(c: Context): Boolean {
        if (!isSupported()) return false
        val cached = prefs(c).getBoolean(PREF_IS_ON, false)
        try {
            val raw = Settings.Secure.getString(c.contentResolver, SETTING_KEY)
            Log.d(TAG, "read OK: raw=$raw cached=$cached ctx=${c.javaClass.simpleName} sdk=${Build.VERSION.SDK_INT}")
            val on = raw == "1"
            prefs(c).edit().putBoolean(PREF_IS_ON, on).apply()
            return on
        } catch (e: SecurityException) {
            Log.e(TAG, "read BLOCKED (SecurityException), using cache=$cached", e)
        } catch (e: Exception) {
            Log.e(TAG, "read FAILED (${e.javaClass.simpleName}), using cache=$cached", e)
        }
        return cached
    }

    /**
     * Sets Extra Dim on or off. Requires WRITE_SECURE_SETTINGS.
     * Also caches the new state in SharedPreferences.
     */
    fun set(c: Context, enable: Boolean): Boolean {
        if (!isSupported() || !DnsManager.hasPermission(c)) return false
        Log.d(TAG, "set($enable)")
        return try {
            val ok = Settings.Secure.putInt(
                c.contentResolver, SETTING_KEY, if (enable) 1 else 0
            )
            if (ok) {
                prefs(c).edit().putBoolean(PREF_IS_ON, enable).apply()
            }
            ok
        } catch (_: Exception) {
            false
        }
    }
}
