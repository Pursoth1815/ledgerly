package com.pursoth.loopd.bridge

import android.app.Activity
import android.content.Context
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.CancellationSignal
import android.util.Log
import android.view.WindowManager
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Pigeon host implementation of [DeviceApi]: the phone's own fingerprint,
 * face or PIN check, and the private window (no recent-apps preview, no
 * screenshots). [MainActivity] hands over the activity with [attach].
 */
class DeviceApiImpl private constructor(private val context: Context) : DeviceApi {
    private var activity: Activity? = null
    private var private = false

    fun attach(activity: Activity?) {
        this.activity = activity
        activity?.let { applyPrivate(it) }
    }

    override fun canCheckOwner(): Boolean =
        context.getSystemService(BiometricManager::class.java)?.canAuthenticate(AUTHENTICATORS) ==
            BiometricManager.BIOMETRIC_SUCCESS

    override suspend fun checkOwner(title: String, subtitle: String): Boolean {
        val host = activity ?: return false
        val ok = OwnerCheck.ask(host, title, subtitle)
        Log.i(TAG, "owner_check passed=$ok")
        return ok
    }

    override fun setPrivateWindow(private: Boolean) {
        this.private = private
        activity?.let { applyPrivate(it) }
        Log.i(TAG, "private_window on=$private")
    }

    private fun applyPrivate(host: Activity) {
        if (private) {
            host.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            host.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        host.setRecentsScreenshotEnabled(!private)
    }

    companion object {
        private const val TAG = "loopd.device"
        const val AUTHENTICATORS = BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL

        @Volatile private var instance: DeviceApiImpl? = null

        fun shared(context: Context): DeviceApiImpl =
            instance ?: synchronized(this) {
                instance ?: DeviceApiImpl(context.applicationContext).also { instance = it }
            }
    }
}

/** The phone's fingerprint, face or PIN prompt, shared by App lock and the backup passphrase reset. */
object OwnerCheck {
    suspend fun ask(host: Activity, title: String, subtitle: String): Boolean = suspendCancellableCoroutine { continuation ->
        val prompt = BiometricPrompt.Builder(host)
            .setTitle(title)
            .setSubtitle(subtitle)
            .setAllowedAuthenticators(DeviceApiImpl.AUTHENTICATORS)
            .build()
        val cancel = CancellationSignal()
        continuation.invokeOnCancellation { cancel.cancel() }
        prompt.authenticate(
            cancel,
            host.mainExecutor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    if (continuation.isActive) continuation.resume(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    if (continuation.isActive) continuation.resume(false)
                }
            },
        )
    }
}
