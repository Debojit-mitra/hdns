package com.hana.utils.hdns

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings
import org.json.JSONArray

object DnsManager {
    private const val PREFS = "hdns_state"
    private const val KEY_PROVIDERS = "providers"
    private const val KEY_LAST = "last_id"
    private const val KEY_OFF_MODE = "off_mode"

    const val MODE_HOSTNAME = "hostname"
    const val MODE_AUTO = "opportunistic"
    const val MODE_OFF = "off"

    data class Provider(val id: String, val name: String, val hostname: String)

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun hasPermission(c: Context): Boolean =
        c.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
            PackageManager.PERMISSION_GRANTED

    // ---- config pushed from Flutter ----
    fun saveConfig(c: Context, providersJson: String, offMode: String) {
        prefs(c).edit()
            .putString(KEY_PROVIDERS, providersJson)
            .putString(KEY_OFF_MODE, if (offMode == MODE_OFF) MODE_OFF else MODE_AUTO)
            .apply()
    }

    fun providers(c: Context): List<Provider> {
        val arr = JSONArray(prefs(c).getString(KEY_PROVIDERS, "[]"))
        return (0 until arr.length()).map {
            val o = arr.getJSONObject(it)
            Provider(o.getString("id"), o.getString("name"), o.getString("hostname"))
        }
    }

    fun offMode(c: Context): String = prefs(c).getString(KEY_OFF_MODE, MODE_AUTO) ?: MODE_AUTO
    fun offLabel(c: Context): String = if (offMode(c) == MODE_OFF) "Off" else "Automatic"
    fun lastId(c: Context): String? = prefs(c).getString(KEY_LAST, null)

    // ---- system state (source of truth) ----
    fun systemMode(c: Context): String? =
        Settings.Global.getString(c.contentResolver, "private_dns_mode")

    fun systemHostname(c: Context): String? =
        Settings.Global.getString(c.contentResolver, "private_dns_specifier")

    fun isOn(c: Context) = systemMode(c) == MODE_HOSTNAME

    fun activeProvider(c: Context): Provider? {
        if (!isOn(c)) return null
        val host = systemHostname(c) ?: return null
        return providers(c).firstOrNull { it.hostname.equals(host, ignoreCase = true) }
    }

    // ---- actions ----
    fun apply(c: Context, id: String): Boolean {
        val p = providers(c).firstOrNull { it.id == id } ?: return false
        return try {
            val r = c.contentResolver
            Settings.Global.putString(r, "private_dns_specifier", p.hostname)
            Settings.Global.putString(r, "private_dns_mode", MODE_HOSTNAME)
            prefs(c).edit().putString(KEY_LAST, p.id).apply()
            true
        } catch (e: SecurityException) {
            false
        }
    }

    fun turnOff(c: Context): Boolean {
        return try {
            activeProvider(c)?.let { prefs(c).edit().putString(KEY_LAST, it.id).apply() }
            Settings.Global.putString(c.contentResolver, "private_dns_mode", offMode(c))
            true
        } catch (e: SecurityException) {
            false
        }
    }

    fun toggle(c: Context): Boolean {
        if (isOn(c)) return turnOff(c)
        val id = lastId(c) ?: providers(c).firstOrNull()?.id ?: return false
        return apply(c, id)
    }
}