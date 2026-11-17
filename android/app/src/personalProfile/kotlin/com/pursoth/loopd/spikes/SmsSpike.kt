package com.pursoth.loopd.spikes

import android.Manifest
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Telephony
import com.pursoth.loopd.background.BackgroundJobWorker
import com.pursoth.loopd.background.BackgroundRuntime
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Phase 0B spike: SMS receive and inbox read (ADR 0007, ADR 0013).
 *
 * Privacy: nothing here stores or shows message text, phone numbers, amounts
 * or account digits. Only counts, six-letter sender codes (such as a bank's
 * code) and timings are reported.
 */
class SmsSpike(private val context: Context) {
    fun hasPermission(permission: String) =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    fun readInbox(report: Report) {
        report(
            "Permissions: READ_SMS ${grant(Manifest.permission.READ_SMS)} · " +
                "RECEIVE_SMS ${grant(Manifest.permission.RECEIVE_SMS)}",
        )
        if (!hasPermission(Manifest.permission.READ_SMS)) {
            report("SMS inbox overall: NOT ALLOWED (tap button 11)")
            return
        }
        val since = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(DAYS)
        val bySender = mutableMapOf<String, Int>()
        var total = 0
        var recent = 0
        var transactional = 0
        val started = System.nanoTime()
        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.DATE, Telephony.Sms.BODY),
            null,
            null,
            "${Telephony.Sms.DATE} DESC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                total++
                if (cursor.getLong(1) < since) continue
                recent++
                bySender.merge(senderCode(cursor.getString(0)), 1, Int::plus)
                if (looksTransactional(cursor.getString(2))) transactional++
            }
        }
        val millis = (System.nanoTime() - started) / 1_000_000
        report("Inbox: $total messages, read in $millis ms")
        report("Last $DAYS days: $recent messages, $transactional look like money messages (debited, credited, spent, UPI…)")
        report("Top senders in the last $DAYS days (code: count):")
        bySender.entries.sortedByDescending { it.value }.take(20).forEach { (code, count) -> report("  $code: $count") }
        report("SMS inbox overall: PASS")
    }

    fun showReceived(report: Report) {
        report("Permission RECEIVE_SMS: ${grant(Manifest.permission.RECEIVE_SMS)}")
        val log = logFile(context).let { if (it.exists()) it.readText().trim() else "" }
        report("New messages received, newest last:")
        if (log.isEmpty()) report("  (none yet)") else log.lines().takeLast(30).forEach { report("  $it") }
        report("Background run log for SMS work, newest last:")
        BackgroundRuntime.get(context).log.read().trim().lines().filter { "sms" in it || "self_test.quick" in it }
            .takeLast(12).ifEmpty { listOf("(none)") }.forEach { report("  $it") }
    }

    private fun grant(permission: String) = if (hasPermission(permission)) "allowed" else "not allowed"

    companion object {
        private const val DAYS = 90L
        private val MONEY_WORDS = Regex("\\b(debited|credited|spent|withdrawn|upi|txn|a/c)\\b", RegexOption.IGNORE_CASE)

        fun logFile(context: Context) = File(context.noBackupFilesDir, "spikes/sms_received.log")

        /**
         * The six-letter sender code from headers such as `AD-HDFCBK` or
         * `VM-HDFCBK-S`. A phone number becomes `phone_number`, so no digits
         * are ever reported.
         */
        fun senderCode(address: String?): String {
            if (address.isNullOrBlank()) return "unknown"
            if (address.none { it.isLetter() }) return "phone_number"
            val parts = address.uppercase(Locale.US).split('-')
            return parts.firstOrNull { it.length == 6 && it.all(Char::isLetter) }
                ?: parts.firstOrNull { it.length > 2 && it.all(Char::isLetterOrDigit) && it.any(Char::isLetter) }
                    ?.let { "other_${it.length}_chars" }
                ?: "other"
        }

        fun looksTransactional(body: String?): Boolean = body != null && MONEY_WORDS.containsMatchIn(body)

        fun stamp(): String = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
    }
}

/**
 * Logs each new SMS (sender code, length, delay, locked) and starts the
 * expedited background job, as the real receiver will (ADR 0013).
 */
class SmsSpikeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        val first = parts.firstOrNull() ?: return
        val chars = parts.sumOf { it.messageBody?.length ?: 0 }
        val delay = (System.currentTimeMillis() - first.timestampMillis) / 1000
        val locked = context.getSystemService(KeyguardManager::class.java)?.isDeviceLocked
        val line = "${SmsSpike.stamp()} sms_received sender=${SmsSpike.senderCode(first.originatingAddress)} " +
            "parts=${parts.size} chars=$chars delay_s=$delay locked=$locked " +
            "money=${SmsSpike.looksTransactional(parts.joinToString("") { it.messageBody ?: "" })}"
        runCatching {
            SmsSpike.logFile(context).apply { parentFile?.mkdirs() }.appendText(line + "\n")
        }
        BackgroundRuntime.get(context).log.add("sms_received start_job=self_test.quick")
        BackgroundJobWorker.enqueue(context, "self_test.quick", uniqueName = "sms_test", expedited = true)
    }
}
