package com.hana.utils.hdns

import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private fun state(ok: Boolean = true): Map<String, Any?> = mapOf(
        "ok" to ok,
        "permission" to DnsManager.hasPermission(this),
        "package" to packageName,
        "mode" to DnsManager.systemMode(this),
        "hostname" to DnsManager.systemHostname(this),
        "activeId" to DnsManager.activeProvider(this)?.id,
        "lastId" to DnsManager.lastId(this),
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hdns/dns")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getState" -> result.success(state())
                    "apply" -> {
                        val id = call.argument<String>("id")
                        result.success(state(id != null && DnsManager.apply(this, id)))
                    }
                    "turnOff" -> result.success(state(DnsManager.turnOff(this)))
                    "syncConfig" -> {
                        DnsManager.saveConfig(
                            this,
                            call.argument<String>("providers") ?: "[]",
                            call.argument<String>("offMode") ?: DnsManager.MODE_AUTO,
                        )
                        result.success(null)
                    }
                    "requestAddTile" -> {
                        if (Build.VERSION.SDK_INT < 33) {
                            result.success(-1)
                        } else {
                            val sbm = getSystemService(StatusBarManager::class.java)
                            sbm.requestAddTileService(
                                ComponentName(this, DnsTileService::class.java),
                                getString(R.string.tile_label),
                                Icon.createWithResource(this, R.drawable.ic_tile_hdns),
                                mainExecutor,
                            ) { code -> result.success(code) }
                        }
                    }
                    "getExtraDimState" -> {
                        val supported = ExtraDimManager.isSupported()
                        val enabled = if (supported) ExtraDimManager.isOn(this) else false
                        result.success(mapOf("supported" to supported, "enabled" to enabled))
                    }
                    "setExtraDim" -> {
                        val enable = call.argument<Boolean>("enabled") ?: false
                        result.success(ExtraDimManager.set(this, enable))
                    }
                    "requestAddExtraDimTile" -> {
                        if (Build.VERSION.SDK_INT < 33) {
                            result.success(-1)
                        } else {
                            val sbm = getSystemService(StatusBarManager::class.java)
                            sbm.requestAddTileService(
                                ComponentName(this, ExtraDimTileService::class.java),
                                getString(R.string.extra_dim_tile_label),
                                Icon.createWithResource(this, R.drawable.ic_tile_extra_dim),
                                mainExecutor,
                            ) { code -> result.success(code) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}