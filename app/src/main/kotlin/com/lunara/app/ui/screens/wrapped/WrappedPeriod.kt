/**
 * Ankit Khatri KC (C) 2026
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import com.lunara.app.R

/**
 * The lookback period for a Wrapped recap.
 *
 * - [Weekly]  — the last 7 days
 * - [Monthly] — the current calendar month to date
 * - [Yearly]  — the current/last full year (the classic December recap)
 */
enum class WrappedPeriod(val label: String, val resId: Int) {
    Weekly("Weekly", R.string.wrapped_period_weekly),
    Monthly("Monthly", R.string.wrapped_period_monthly),
    Yearly("Yearly", R.string.wrapped_period_yearly);

    companion object {
        fun all() = listOf(Weekly, Monthly, Yearly)
    }
}
