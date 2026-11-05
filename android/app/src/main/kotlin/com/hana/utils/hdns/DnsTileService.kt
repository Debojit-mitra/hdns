package com.hana.utils.hdns

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class DnsTileService : TileService() {

    override fun onStartListening() = refresh()

    override fun onClick() {
        if (!DnsManager.hasPermission(this)) {
            openApp()
            return
        }
        DnsManager.toggle(this)
        refresh()
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val granted = DnsManager.hasPermission(this)
        val on = granted && DnsManager.isOn(this)
        val name = DnsManager.activeProvider(this)?.name
            ?: DnsManager.systemHostname(this)
            ?: "On"

        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        val subtitle = when {
            !granted -> "Setup needed"
            on -> name
            else -> DnsManager.offLabel(this)
        }
        if (Build.VERSION.SDK_INT >= 29) {
            tile.label = getString(R.string.tile_label)
            tile.subtitle = subtitle
        } else {
            tile.label = if (on) name else getString(R.string.tile_label)
        }
        tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_hdns)
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