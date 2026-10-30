/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Which period Wrapped looks back on, and when it is offered.
 *
 * Weekly Wrapped is always available so users can revisit their recent listening anytime.
 */
object WrappedConstants {
    /** Human-readable name of the generated Wrapped playlist for [period]. */
    fun playlistName(period: WrappedPeriod, today: LocalDate = LocalDate.now()): String =
        when (period) {
            WrappedPeriod.Weekly -> "Lunara Weekly ${today.format(DateTimeFormatter.ofPattern("dd MMM", Locale.getDefault()))}"
        }

    /** Short label shown on story cards for [period]. */
    fun periodLabel(period: WrappedPeriod): String = when (period) {
        WrappedPeriod.Weekly -> "This week"
    }

    /** The inclusive start of the lookback window for [period]. */
    fun start(period: WrappedPeriod, today: LocalDate = LocalDate.now()): LocalDateTime =
        when (period) {
            WrappedPeriod.Weekly -> today.minusDays(6).atStartOfDay()
        }

    /** The inclusive end of the lookback window for [period]. */
    fun end(period: WrappedPeriod, today: LocalDate = LocalDate.now()): LocalDateTime =
        when (period) {
            WrappedPeriod.Weekly -> today.atTime(23, 59, 59)
        }
}
