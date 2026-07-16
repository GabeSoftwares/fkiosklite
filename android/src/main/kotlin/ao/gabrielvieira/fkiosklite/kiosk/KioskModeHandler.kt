package ao.gabrielvieira.fkiosklite.kiosk

import android.app.Activity
import android.app.ActivityManager
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.UserManager
import java.io.File
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

            "rebootDevice" -> {
                try {
                    rebootDevice()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("REBOOT_ERROR", e.message, null)
                }
            }

            "shutdownDevice" -> {
                try {
                    shutdownDevice()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SHUTDOWN_ERROR", e.message, null)
                }
            }

            "canShutdown" -> {
                result.success(canShutdown())
            }

            "enableAutoStart" -> {
                setAutoStart(currentActivity!!, true)
                result.success(null)
            }

            "disableAutoStart" -> {
                setAutoStart(currentActivity!!, false)
                result.success(null)
            }

            "uninstallApp" -> {
                val packageName = call.argument<String>("packageName") ?: run {
                    result.error("INVALID_ARGS", "packageName required", null)
                    return
                }
                uninstallApp(packageName, result)
            }

            "setAppHidden" -> {
                val packageName = call.argument<String>("packageName") ?: run {
                    result.error("INVALID_ARGS", "packageName required", null)
                    return
                }
                val hidden = call.argument<Boolean>("hidden") ?: true
                try {
                    if (!dpm.isDeviceOwnerApp(currentActivity!!.packageName)) {
                        result.error("NOT_DEVICE_OWNER", "App is not Device Owner", null)
                        return
                    }
                    val success = dpm.setApplicationHidden(adminComponent, packageName, hidden)
                    result.success(success)
                } catch (e: Exception) {
                    result.error("APP_HIDDEN_ERROR", e.message, null)
                }
            }

            "wipeData" -> {
                try {
                    wipeData()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("WIPE_ERROR", e.message, null)
                }
            }

            "clearDeviceOwner" -> {
                try {
                    if (!dpm.isDeviceOwnerApp(currentActivity!!.packageName)) {
                        result.error("NOT_DEVICE_OWNER", "App is not Device Owner", null)
                        return
                    }
                    dpm.clearDeviceOwnerApp(currentActivity.packageName)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CLEAR_OWNER_ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun setAutoStart(context: Context, enabled: Boolean) {
        val component = ComponentName(
            context.packageName,
            "ao.gabrielvieira.fkiosklite.boot.BootReceiver"
        )
        context.packageManager.setComponentEnabledSetting(
            component,
            if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
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
        // setLockTaskFeatures() was added in API 28 (Android 9). Below that,
        // Lock Task Mode still works but is all-or-nothing (no customization
        // API exists), so the fine-grained toggles are silently ignored.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            dpm.setLockTaskFeatures(adminComponent, LockTaskFeatures.fromConfig(config))
        }

        currentActivity.startLockTask()
        eventSink?.success(true)
    }

    private fun disableKiosk() {
        activity?.stopLockTask()
        // Re-enable ADB and unknown-source installs when kiosk is turned off
        // so the device owner can update or debug the device again.
        if (dpm.isDeviceOwnerApp(activity?.packageName ?: "")) {
            runCatching {
                dpm.clearUserRestriction(adminComponent, UserManager.DISALLOW_DEBUGGING_FEATURES)
            }
            runCatching {
                dpm.clearUserRestriction(adminComponent, UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES)
            }
        }
        eventSink?.success(false)
    }

    private fun rebootDevice() {
        if (!dpm.isDeviceOwnerApp(activity!!.packageName)) {
            throw IllegalStateException("App is not Device Owner")
        }
        dpm.reboot(adminComponent)
    }

    /**
     * Attempts to power the device off.
     *
     * Unlike [rebootDevice] — which uses the public [DevicePolicyManager.reboot]
     * API supported for any Device Owner since API 24 — the AOSP framework
     * exposes NO public shutdown/power-off equivalent to Device Owner apps in
     * any version (verified through Android 15). Powering off therefore requires
     * one of two privilege paths this method tries in order:
     *
     *  1. Direct `/system/bin/reboot -p` — only works if the process is allowed
     *     to write the `sys.powerctl` system property. A stock `untrusted_app`
     *     Device Owner is blocked by SELinux, so this fails on retail devices.
     *  2. `su -c "reboot -p"` — works on rooted kiosk/POS hardware where a `su`
     *     binary is present.
     *  3. `REQUEST_SHUTDOWN` intent — only works for a system-signed / priv-app
     *     holding the signature|privileged `android.permission.SHUTDOWN`.
     *
     * If none succeed, an [IllegalStateException] is thrown with an actionable
     * message stating that shutdown needs root or system-app privileges.
     */
    private fun shutdownDevice() {
        if (!dpm.isDeviceOwnerApp(activity!!.packageName)) {
            throw IllegalStateException("App is not Device Owner")
        }

        // Attempt 1: direct property write via the reboot binary. Blocked by
        // SELinux for a stock untrusted_app Device Owner, but succeeds on
        // system/priv-app builds.
        val directExitCode = execForExitCode(arrayOf("/system/bin/reboot", "-p"))
        if (directExitCode == 0) return

        // Attempt 2: root shell. Common on dedicated POS/kiosk hardware that
        // ships rooted. No-op on non-rooted retail devices (su absent).
        val suExitCode = execForExitCode(arrayOf("su", "-c", "/system/bin/reboot -p"))
        if (suExitCode == 0) return

        // Attempt 3: privileged system shutdown intent. Requires the
        // signature|privileged android.permission.SHUTDOWN, which Device Owner
        // status alone does NOT grant.
        val intentError = runCatching {
            val intent = Intent("com.android.internal.intent.action.REQUEST_SHUTDOWN").apply {
                putExtra("android.intent.extra.KEY_CONFIRM", false)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            activity!!.startActivity(intent)
        }.exceptionOrNull()

        val directMsg = describeExit("/system/bin/reboot -p", directExitCode)
        val suMsg = describeExit("su -c 'reboot -p'", suExitCode)
        val intentMsg = intentError
            ?.let { "REQUEST_SHUTDOWN intent rejected (${it::class.java.simpleName})" }
            ?: "REQUEST_SHUTDOWN intent sent but the OS did not power off"

        throw IllegalStateException(
            "Unable to power off the device. On stock hardware, shutting down " +
                "is not available to a Device Owner: unlike reboot, Android exposes " +
                "no DevicePolicyManager shutdown API, and SELinux blocks writing " +
                "sys.powerctl. Powering off requires either root (a 'su' binary) or " +
                "the app to be a system/priv-app holding android.permission.SHUTDOWN. " +
                "Use rebootDevice() where a full power-off is not strictly required. " +
                "[$directMsg; $suMsg; $intentMsg]"
        )
    }

    /**
     * Runs [command], waits for it, closes its streams, and returns the exit
     * code, or `null` if the process could not be spawned (e.g. binary absent).
     */
    private fun execForExitCode(command: Array<String>): Int? = runCatching {
        val process = Runtime.getRuntime().exec(command)
        val exitCode = process.waitFor()
        // Best-effort cleanup; avoid leaking file descriptors.
        runCatching { process.inputStream.close() }
        runCatching { process.errorStream.close() }
        runCatching { process.outputStream.close() }
        exitCode
    }.getOrNull()

    private fun describeExit(command: String, exitCode: Int?): String = when (exitCode) {
        null -> "$command could not be executed"
        else -> "$command exited with code=$exitCode"
    }

    /**
     * Best-effort check for whether [shutdownDevice] is likely to succeed.
     *
     * Mirrors [canSilentInstall] on the update plugin so integrators can gate
     * the shutdown action in the UI instead of discovering the limitation via
     * an exception. Returns `true` when either viable privilege path is
     * detectable: a `su` binary on PATH (rooted hardware) or the app already
     * holding the privileged SHUTDOWN permission (system/priv-app). It cannot
     * guarantee success and does not detect the direct property-write path,
     * which is unavailable to stock Device Owner apps anyway.
     */
    private fun canShutdown(): Boolean {
        val hasShutdownPermission = activity?.let {
            it.checkCallingOrSelfPermission("android.permission.SHUTDOWN") ==
                PackageManager.PERMISSION_GRANTED
        } ?: false
        return hasShutdownPermission || isSuAvailable()
    }

    /** Heuristic root detection: looks for a `su` binary in the common paths. */
    private fun isSuAvailable(): Boolean {
        val candidates = listOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/su/bin/su",
            "/vendor/bin/su",
            "/system/sbin/su"
        )
        return candidates.any { runCatching { File(it).exists() }.getOrDefault(false) }
    }

    private fun uninstallApp(packageName: String, result: MethodChannel.Result) {
        val ctx = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        if (!dpm.isDeviceOwnerApp(ctx.packageName)) {
            result.error("NOT_DEVICE_OWNER", "App is not Device Owner", null)
            return
        }
        val intent = Intent("ao.gabrielvieira.fkiosklite.UNINSTALL_COMPLETE").apply {
            setPackage(ctx.packageName)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            ctx, packageName.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            ctx.packageManager.packageInstaller.uninstall(packageName, pendingIntent.intentSender)
            result.success(null)
        } catch (e: Exception) {
            result.error("UNINSTALL_ERROR", e.message, null)
        }
    }

    private fun wipeData() {
        if (!dpm.isDeviceOwnerApp(activity!!.packageName)) {
            throw IllegalStateException("App is not Device Owner")
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            DevicePolicyManager.WIPE_SILENTLY
        } else {
            0
        }
        @Suppress("DEPRECATION")
        dpm.wipeData(flags)
    }

    private fun setFeatures(featureValues: List<Int>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            dpm.setLockTaskFeatures(adminComponent, LockTaskFeatures.combinedFlags(featureValues))
        }
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
