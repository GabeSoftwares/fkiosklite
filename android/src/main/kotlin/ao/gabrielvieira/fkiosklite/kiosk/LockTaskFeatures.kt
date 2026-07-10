package ao.gabrielvieira.fkiosklite.kiosk

import android.app.admin.DevicePolicyManager

object LockTaskFeatures {

    fun combinedFlags(featureValues: List<Int>): Int {
        var flags = DevicePolicyManager.LOCK_TASK_FEATURE_NONE
        for (value in featureValues) {
            flags = flags or value
        }
        return flags
    }

    fun fromConfig(config: Map<String, Any>?): Int {
        if (config == null) return DevicePolicyManager.LOCK_TASK_FEATURE_NONE

        var flags = DevicePolicyManager.LOCK_TASK_FEATURE_NONE
        if (config["showStatusBar"] == true)
            flags = flags or DevicePolicyManager.LOCK_TASK_FEATURE_SYSTEM_INFO
        if (config["showNotifications"] == true)
            flags = flags or DevicePolicyManager.LOCK_TASK_FEATURE_NOTIFICATIONS
        if (config["enableHomeButton"] == true)
            flags = flags or DevicePolicyManager.LOCK_TASK_FEATURE_HOME
        if (config["enableOverviewButton"] == true)
            flags = flags or DevicePolicyManager.LOCK_TASK_FEATURE_OVERVIEW
        if (config["enablePowerButton"] == true)
            flags = flags or DevicePolicyManager.LOCK_TASK_FEATURE_GLOBAL_ACTIONS

        return flags
    }
}
