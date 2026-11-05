package com.hana.utils.hdns

import android.app.Activity
import android.app.AlertDialog
import android.content.ComponentName
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.widget.Toast

class TilePickerActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (isExtraDimIntent()) {
            val opened = try {
                startActivity(
                    Intent("android.settings.REDUCE_BRIGHT_COLORS_SETTINGS")
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                true
            } catch (_: Exception) {
                false
            }
            if (!opened) {
                packageManager.getLaunchIntentForPackage(packageName)?.let {
                    startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            }
            finish()
            return
        }

        val providers = DnsManager.providers(this)
        if (!DnsManager.hasPermission(this) || providers.isEmpty()) {
            Toast.makeText(this, "Finish HDNS setup first", Toast.LENGTH_LONG).show()
            packageManager.getLaunchIntentForPackage(packageName)?.let {
                startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            finish()
            return
        }

        val names = (listOf(DnsManager.offLabel(this)) + providers.map { it.name }).toTypedArray()
        val active = DnsManager.activeProvider(this)
        val checked = when {
            active != null -> providers.indexOfFirst { it.id == active.id } + 1
            DnsManager.isOn(this) -> -1 // custom hostname set outside HDNS
            else -> 0
        }

        val night = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
        val theme = if (night) android.R.style.Theme_DeviceDefault_Dialog_Alert
        else android.R.style.Theme_DeviceDefault_Light_Dialog_Alert

        AlertDialog.Builder(this, theme)
            .setTitle("Choose DNS")
            .setSingleChoiceItems(names, checked) { dialog, which ->
                if (which == 0) DnsManager.turnOff(this)
                else DnsManager.apply(this, providers[which - 1].id)
                dialog.dismiss()
            }
            .setOnDismissListener { finish() }
            .show()
    }

    private fun isExtraDimIntent(): Boolean {
        val comp: ComponentName? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_COMPONENT_NAME, ComponentName::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_COMPONENT_NAME)
        }
        if (comp != null && comp.className.contains("ExtraDim")) return true

        val strComp = intent.getStringExtra(Intent.EXTRA_COMPONENT_NAME)
            ?: intent.getStringExtra("android.intent.extra.COMPONENT_NAME")
            ?: ""
        return strComp.contains("ExtraDim")
    }
}
