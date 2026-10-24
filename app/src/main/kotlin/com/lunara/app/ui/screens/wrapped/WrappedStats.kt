/**
 * Ankit Khatri KC (C) 2026
 * Lunara Wrapped statistics data class.
 *
 * Holds the aggregated play counts and timestamps for weekly, monthly, and yearly wrapped views.
 */
import com.lunara.app.db.entities.LocalItem

import androidx.annotation.Immutable

@Immutable
data class WrappedStats(
    /** Total play count for the current week (resets every Sunday) */
    val weeklyPlayCount: Int = 0,
    /** Total play count for the current month (resets 1st of month) */
    val monthlyPlayCount: Int = 0,
    /** Total play count for the current year (resets 1st of year) */
    val yearlyPlayCount: Int = 0,
    /** Timestamp of the last week reset (midnight Sunday) */
    val weeklyLastReset: Long = 0L,
    /** Timestamp of the last month reset (midnight 1st) */
    val monthlyLastReset: Long = 0L,
    /** Timestamp of the last year reset (midnight 1st Jan) */
    val yearlyLastReset: Long = 0L,
    /** Flag indicating if weekly wrapped has been shown this cycle */
    val weeklyShown: Boolean = false,
    /** Flag indicating if monthly wrapped has been shown this cycle */
    val monthlyShown: Boolean = false,
    /** Flag indicating if yearly wrapped has been shown this cycle */
    val yearlyShown: Boolean = false
) : LocalItem()