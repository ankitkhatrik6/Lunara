/** 
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import com.lunara.app.R

/**
 * The lookback period for a Wrapped recap.
 *
 * - [Weekly] — the last 7 days
 */
enum class WrappedPeriod(val label: String, val resId: Int) {
    Weekly("Weekly", R.string.wrapped_period_weekly);

    companion object {
        fun all() = listOf(Weekly)
    }
}
