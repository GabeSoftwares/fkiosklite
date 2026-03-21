package ao.gabrielvieira.fkiosk.kiosk

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class KioskModeHandler(
    private var activity: Activity?,
    private val dpm: DevicePolicyManager,
    private val adminComponent: ComponentName
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null && call.method != "isDeviceOwner") {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        when (call.method) {
            "isDeviceOwner" -> {
                val pkg = activity?.packageName
                    ?: return result.success(false)
                result.success(dpm.isDeviceOwnerApp(pkg))
            }

            "isInKioskMode" -> {
                val activityManager = currentActivity!!.getSystemService(
                    Context.ACTIVITY_SERVICE
                ) as ActivityManager
                result.success(
                    activityManager.lockTaskModeState
                        != ActivityManager.LOCK_TASK_MODE_NONE
                )
            }

            "enableKioskMode" -> {
                try {
                    @Suppress("UNCHECKED_CAST")
                    enableKiosk(call.arguments as? Map<String, Any>)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            }

            "disableKioskMode" -> {
                try {
                    disableKiosk()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            }

            "setKioskFeatures" -> {
                @Suppress("UNCHECKED_CAST")
                val features = call.arguments as? List<Int> ?: emptyList()
                setFeatures(features)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun enableKiosk(config: Map<String, Any>?) {
        val currentActivity = activity
            ?: throw IllegalStateException("Activity not available")

        if (!dpm.isDeviceOwnerApp(currentActivity.packageName)) {
            throw IllegalStateException("App is not Device Owner")
        }

        val packages = mutableListOf(currentActivity.packageName)
        @Suppress("UNCHECKED_CAST")
        val additional = config?.get("allowedPackages") as? List<String>
        if (additional != null) packages.addAll(additional)

        dpm.setLockTaskPackages(adminComponent, packages.toTypedArray())
        dpm.setLockTaskFeatures(adminComponent, LockTaskFeatures.fromConfig(config))

        currentActivity.startLockTask()
        eventSink?.success(true)
    }

    private fun disableKiosk() {
        activity?.stopLockTask()
        eventSink?.success(false)
    }

    private fun setFeatures(featureValues: List<Int>) {
        dpm.setLockTaskFeatures(adminComponent, LockTaskFeatures.combinedFlags(featureValues))
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
