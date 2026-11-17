package com.pursoth.loopd.spikes

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SmsSpikeTest {
    @Test
    fun senderHeadersBecomeTheirSixLetterCode() {
        assertEquals("HDFCBK", SmsSpike.senderCode("AD-HDFCBK"))
        assertEquals("HDFCBK", SmsSpike.senderCode("VM-HDFCBK-S"))
        assertEquals("ICICIT", SmsSpike.senderCode("jd-icicit-t"))
    }

    @Test
    fun phoneNumbersNeverShowTheirDigits() {
        assertEquals("phone_number", SmsSpike.senderCode("+919876543210"))
        assertEquals("phone_number", SmsSpike.senderCode("09876543210"))
        assertEquals("unknown", SmsSpike.senderCode(null))
    }

    @Test
    fun otherSendersOnlyShowTheirLength() {
        assertEquals("other_8_chars", SmsSpike.senderCode("AX-AMAZONIN"))
    }

    @Test
    fun moneyWordsAreSpottedWithoutKeepingTheText() {
        assertTrue(SmsSpike.looksTransactional("Rs 120.00 debited from A/c XX1234"))
        assertTrue(SmsSpike.looksTransactional("UPI txn successful"))
        assertFalse(SmsSpike.looksTransactional("Your OTP is 123456"))
        assertFalse(SmsSpike.looksTransactional(null))
    }
}
