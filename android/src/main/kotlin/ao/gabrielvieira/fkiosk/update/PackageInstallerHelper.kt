package ao.gabrielvieira.fkiosk.update

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import java.io.File

class PackageInstallerHelper(private val context: Context) {

    fun installApk(apkFile: File): Int {
        val packageInstaller = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL
        )
        params.setAppPackageName(context.packageName)

        val sessionId = packageInstaller.createSession(params)
        val session = packageInstaller.openSession(sessionId)

        session.openWrite("app.apk", 0, apkFile.length()).use { output ->
            apkFile.inputStream().use { input ->
                input.copyTo(output)
            }
            session.fsync(output)
        }

        val intent = Intent(context, UpdateReceiver::class.java).apply {
            action = ACTION_INSTALL_STATUS
            putExtra(EXTRA_SESSION_ID, sessionId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, sessionId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        session.commit(pendingIntent.intentSender)

        return sessionId
    }

    fun uninstallPackage(packageName: String): Boolean {
        return try {
            val intent = Intent(context, UpdateReceiver::class.java).apply {
                action = ACTION_UNINSTALL_STATUS
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            context.packageManager.packageInstaller.uninstall(
                packageName, pendingIntent.intentSender
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val ACTION_INSTALL_STATUS =
            "ao.gabrielvieira.fkiosk.ACTION_INSTALL_STATUS"
        const val ACTION_UNINSTALL_STATUS =
            "ao.gabrielvieira.fkiosk.ACTION_UNINSTALL_STATUS"
        const val EXTRA_SESSION_ID = "session_id"
    }
}
