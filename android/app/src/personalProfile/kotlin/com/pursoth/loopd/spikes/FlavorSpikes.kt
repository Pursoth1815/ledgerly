package com.pursoth.loopd.spikes

import android.Manifest
import android.widget.LinearLayout

/** SMS spike buttons, in the personal build only (ADR 0017). */
object FlavorSpikes {
    fun addButtons(lab: SpikeLabActivity, column: LinearLayout) {
        lab.addButton(column, "11 · SMS: allow SMS permission") {
            lab.requestPermissions(arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS), 11)
        }
        lab.addButton(column, "12 · SMS: read the inbox (counts only)") {
            lab.runSpike("SMS inbox") { report -> SmsSpike(lab.applicationContext).readInbox(report) }
        }
        lab.addButton(column, "13 · SMS: new messages received") {
            lab.runSpike("SMS received") { report -> SmsSpike(lab.applicationContext).showReceived(report) }
        }
    }
}
