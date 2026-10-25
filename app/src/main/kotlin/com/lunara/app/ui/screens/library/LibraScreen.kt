package com.lunara.app.ui.screens.library

import androidx.compose.runtime.Composable
import com.lunara.app.LocalNavController

@Composable
fun LibraScreen() {
    val navController = LocalNavController.current
    LunaraLibraryHome(navController)
}