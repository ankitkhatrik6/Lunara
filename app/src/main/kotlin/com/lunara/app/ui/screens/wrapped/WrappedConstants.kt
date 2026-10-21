/**
 * Ankit Khatri KC (C) 2026
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.Month
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

/**
 * Which period Wrapped looks back on, and when it is offered.
 *
 * The year used to be fixed to 2025, so once that season ended Wrapped never came back. Now
 * December looks back on the year that is ending, and every other month on the last full year.
 * The Home card is offered in December and January, the way a yearly recap is.
 *
 * Weekly and Monthly recaps are always available so users can revisit their recent listening
 * anytime; Yearly remains the seasonal "big" recap.
 */
object WrappedConstants {
    /** The reference year used by the classic Yearly Wrapped. */
    fun year(today: LocalDate = LocalDate.now()): Int =
        if (today.month == Month.DECEMBER) today.year else today.year - 1

    fun isSeason(today: LocalDate = LocalDate.now()): Boolean =
        today.month == Month.DECEMBER || today.month == Month.JANUARY

    /** The inclusive start of the lookback window for [period]. */
    fun start(period: WrappedPeriod, today: LocalDate = LocalDate.now()): LocalDateTime =
        when (period) {
            WrappedPeriod.Weekly -> today.minusDays(6).atStartOfDay()
            WrappedPeriod.Monthly -> YearMonth.from(today).atDay(1).atStartOfDay()
            WrappedPeriod.Yearly -> {
                val y = year(today)
                LocalDateTime.of(y, 1, 1, 0, 0, 0)
            }
        }

    /** The inclusive end of the lookback window for [period]. */
    fun end(period: WrappedPeriod, today: LocalDate = LocalDate.now()): LocalDateTime =
        when (period) {
            WrappedPeriod.Weekly -> today.atTime(23, 59, 59)
            WrappedPeriod.Monthly -> YearMonth.from(today).atEndOfMonth().atTime(23, 59, 59)
            WrappedPeriod.Yearly -> {
                val y = year(today)
                LocalDateTime.of(y, 12, 31, 23, 59, 59)
            }
        }

    /** Human-readable name of the generated Wrapped playlist for [period]. */
    fun playlistName(period: WrappedPeriod, today: LocalDate = LocalDate.now()): String =
        when (period) {
            WrappedPeriod.Weekly -> "Lunara Weekly ${today.format(DateTimeFormatter.ofPattern("dd MMM", Locale.getDefault()))}"
            WrappedPeriod.Monthly -> {
                val month = YearMonth.from(today)
                "Lunara ${month.month.getDisplayName(TextStyle.FULL, Locale.getDefault())} ${month.year}"
            }
            WrappedPeriod.Yearly -> "Lunara ${year(today)}"
        }

    /** Short label shown on story cards for [period]. */
    fun periodLabel(period: WrappedPeriod): String = when (period) {
        WrappedPeriod.Weekly -> "This week"
        WrappedPeriod.Monthly -> "This month"
        WrappedPeriod.Yearly -> "This year"
    }
}
