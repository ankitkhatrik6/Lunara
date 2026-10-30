/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 *
 * Holds the aggregated play counts for the weekly wrapped view.
 */
package com.lunara.app.ui.screens.wrapped

data class WrappedStats(
    /** Total play count for the current week (resets every Sunday) */
    val weeklyPlayCount: Int = 0,
)
