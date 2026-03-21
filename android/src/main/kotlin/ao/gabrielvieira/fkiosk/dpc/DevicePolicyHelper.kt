package ao.gabrielvieira.fkiosk.dpc

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

        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_DEBUGGING_FEATURES)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_FACTORY_RESET)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_SAFE_BOOT)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_ADD_USER)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES)
        dpm.addUserRestriction(adminComponent, UserManager.DISALLOW_USB_FILE_TRANSFER)

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
