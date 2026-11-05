package com.hana.utils.hdns

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log

/**
 * Quick Settings tile for toggling Extra Dim (Reduce Bright Colors).
 *
 * All reads go through [ExtraDimManager.isOn] which catches the
 * SecurityException thrown on S+ for the @hide setting key and
 * falls back to a SharedPreferences cache. Writes still work
 * via [ExtraDimManager.set] (WRITE_SECURE_SETTINGS).
 */
class ExtraDimTileService : TileService() {

    private val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            Log.d("HDNS_DIM", "observer fired selfChange=$selfChange")
            updateTile()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        contentResolver.registerContentObserver(
            Settings.Secure.getUriFor(ExtraDimManager.SETTING_KEY), false, observer
        )
        updateTile()
    }

    override fun onStopListening() {
        contentResolver.unregisterContentObserver(observer)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        if (!ExtraDimManager.isSupported()) return
        if (!DnsManager.hasPermission(this)) {
            openApp()
            return
        }

        val isOn = ExtraDimManager.isOn(this)
        ExtraDimManager.set(this, !isOn)
        updateTile()
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_extra_dim)

        if (!ExtraDimManager.isSupported()) {
            tile.state = Tile.STATE_UNAVAILABLE
            tile.label = getString(R.string.extra_dim_tile_label)
            if (Build.VERSION.SDK_INT >= 29) tile.subtitle = "Unsupported"
            tile.updateTile()
            return
        }

        if (!DnsManager.hasPermission(this)) {
            tile.state = Tile.STATE_INACTIVE
            tile.label = getString(R.string.extra_dim_tile_label)
            if (Build.VERSION.SDK_INT >= 29) tile.subtitle = "Setup needed"
            tile.updateTile()
            return
        }

        val on = ExtraDimManager.isOn(this)
        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= 29) {
            tile.label = getString(R.string.extra_dim_tile_label)
            tile.subtitle = if (on) "On" else "Off"
        } else {
            tile.label = if (on) "Extra Dim: On" else getString(R.string.extra_dim_tile_label)
        }
        tile.updateTile()
    }

    private fun openApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) ?: return
        if (Build.VERSION.SDK_INT >= 34) {
            val pi = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
            startActivityAndCollapse(pi)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
