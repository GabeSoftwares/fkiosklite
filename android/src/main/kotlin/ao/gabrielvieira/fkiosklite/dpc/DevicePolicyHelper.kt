package ao.gabrielvieira.fkiosklite.dpc

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.UserManager

class DevicePolicyHelper(
    private val context: Context,
    private val dpm: DevicePolicyManager,
    private val adminComponent: ComponentName
) {

    fun isDeviceOwner(): Boolean {
        return dpm.isDeviceOwnerApp(context.packageName)
    }

    fun applySecurityPolicies() {
        if (!isDeviceOwner()) return

        // Keep USB debugging available so the device owner can update the app via ADB.
        // Silent install via PackageInstaller (Device Owner) is the intended update path —
        // DISALLOW_INSTALL_UNKNOWN_SOURCES is not needed and blocks recovery when silent
        // install hasn't been wired up yet.
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_FACTORY_RESET)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_SAFE_BOOT)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_ADD_USER)

        dpm.addPersistentPreferredActivity(
            adminComponent,
            IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            },
            ComponentName(context.packageName, "${context.packageName}.MainActivity")
        )
    }
}
