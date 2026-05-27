package ao.gabrielvieira.fkiosk

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.Context
import ao.gabrielvieira.fkiosk.dpc.AdminReceiver
import ao.gabrielvieira.fkiosk.kiosk.KioskModeHandler
import ao.gabrielvieira.fkiosk.update.SilentUpdateHandler
import ao.gabrielvieira.fkiosk.update.UpdateEventEmitter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class FKioskPlugin : FlutterPlugin, ActivityAware {

    private lateinit var kioskMethodChannel: MethodChannel
    private lateinit var kioskEventChannel: EventChannel
    private lateinit var updateMethodChannel: MethodChannel
    private lateinit var updateEventChannel: EventChannel

    private var kioskModeHandler: KioskModeHandler? = null
    private var silentUpdateHandler: SilentUpdateHandler? = null

    private var applicationContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        kioskMethodChannel = MethodChannel(binding.binaryMessenger, "ao.gabrielvieira.fkiosk/kiosk_mode")
        kioskEventChannel = EventChannel(binding.binaryMessenger, "ao.gabrielvieira.fkiosk/kiosk_mode_events")
        updateMethodChannel = MethodChannel(binding.binaryMessenger, "ao.gabrielvieira.fkiosk/silent_update")
        updateEventChannel = EventChannel(binding.binaryMessenger, "ao.gabrielvieira.fkiosk/update_events")

        // Update handler can work with just context
        val context = binding.applicationContext
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

        silentUpdateHandler = SilentUpdateHandler(context, dpm)
        updateMethodChannel.setMethodCallHandler(silentUpdateHandler)
        updateEventChannel.setStreamHandler(UpdateEventEmitter)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        kioskMethodChannel.setMethodCallHandler(null)
        kioskEventChannel.setStreamHandler(null)
        updateMethodChannel.setMethodCallHandler(null)
        updateEventChannel.setStreamHandler(null)
        kioskModeHandler = null
        silentUpdateHandler = null
        applicationContext = null
    }

    // ActivityAware — kiosk mode needs an Activity for startLockTask/stopLockTask
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        setupKioskHandler(binding.activity)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        setupKioskHandler(binding.activity)
    }

    override fun onDetachedFromActivity() {
        kioskModeHandler?.setActivity(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        kioskModeHandler?.setActivity(null)
    }

    private fun setupKioskHandler(activity: Activity) {
        val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        // Use the actual active admin for this package, not the fkiosk stub receiver.
        // When the app registers its own DeviceAdminReceiver (e.g. CppcfbDeviceAdminReceiver)
        // and sets it as device owner, setLockTaskPackages/setLockTaskFeatures require that
        // exact component — passing AdminReceiver would throw a SecurityException.
        val adminComponent = dpm.activeAdmins
            ?.firstOrNull { it.packageName == activity.packageName }
            ?: AdminReceiver.getComponentName(activity)

        if (kioskModeHandler == null) {
            kioskModeHandler = KioskModeHandler(activity, dpm, adminComponent)
            kioskMethodChannel.setMethodCallHandler(kioskModeHandler)
            kioskEventChannel.setStreamHandler(kioskModeHandler)
        } else {
            kioskModeHandler!!.setActivity(activity)
        }
    }
}
