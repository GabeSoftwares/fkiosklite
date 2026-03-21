package ao.gabrielvieira.fkiosk.update

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object UpdateEventEmitter : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun send(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
