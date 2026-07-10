package ao.gabrielvieira.fkiosklite.update

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller

class UpdateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE
        )
        val sessionId = intent.getIntExtra(
            PackageInstallerHelper.EXTRA_SESSION_ID, -1
        )

        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @Suppress("DEPRECATION")
                val confirmIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                confirmIntent?.let {
                    it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(it)
                }
            }
            PackageInstaller.STATUS_SUCCESS -> {
                notifyFlutter(sessionId, "success", 1.0, null)
            }
            else -> {
                val message = intent.getStringExtra(
                    PackageInstaller.EXTRA_STATUS_MESSAGE
                )
                notifyFlutter(sessionId, "failed", 0.0, message)
            }
        }
    }

    private fun notifyFlutter(
        sessionId: Int,
        state: String,
        progress: Double,
        error: String?
    ) {
        UpdateEventEmitter.send(
            mapOf(
                "sessionId" to sessionId,
                "state" to state,
                "progress" to progress,
                "error" to error,
            )
        )
    }
}
